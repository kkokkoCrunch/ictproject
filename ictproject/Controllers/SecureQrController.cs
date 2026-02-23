using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Security.Claims;
using System.Linq;
using ictproject.Data;

namespace ictproject.Controllers;


[ApiController]
public class SecureQrController : ControllerBase
{
    // Swapped the private static lines to DB


    /* For reference if yall want the lines for MVP: in-memory stores, here it is 
    private static readonly ConcurrentDictionary<Guid, Session> Sessions = new();
    private static readonly ConcurrentDictionary<string, TokenRecord> Tokens = new();
    private static readonly ConcurrentDictionary<Guid, ConcurrentDictionary<string, AttendanceRecord>> AttendanceBySession = new();
    private static readonly ConcurrentBag<ScanEvent> ScanEvents = new();
    private static readonly ConcurrentBag<SecurityIncident> SecurityIncidents = new();
    */
    private readonly AppDbContext _db;

    public SecureQrController(AppDbContext db)
    {
        _db = db;
    }

    // 1) Create time-gated session
    [Authorize(Roles = "Lecturer,Admin")]
    [HttpPost("api/sessions")]
    public IActionResult CreateSession([FromBody] CreateSessionRequest req)
    {
        var session = new Session
        {
            Id = Guid.NewGuid(),
            Name = req.Name,
            ValidFromUtc = req.ValidFromUtc,
            ValidToUtc = req.ValidToUtc,
            RotationSeconds = req.RotationSeconds <= 0 ? 30 : req.RotationSeconds,

            SuccessRedirectUrl = req.SuccessRedirectUrl,
            ExpiredRedirectUrl = req.ExpiredRedirectUrl,
            OutsideWindowRedirectUrl = req.OutsideWindowRedirectUrl,
            InvalidRedirectUrl = req.InvalidRedirectUrl
        };

        _db.Sessions.Add(session);
        _db.SaveChanges();

        return Ok(new { sessionId = session.Id });
    }

    // 2) Rotate short-lived token (dynamic QR)
    [Authorize(Roles = "Lecturer,Admin")]
    [HttpPost("api/sessions/{sessionId:guid}/rotate")]
    public IActionResult Rotate([FromRoute] Guid sessionId)
    {
        var session = _db.Sessions.FirstOrDefault(s => s.Id == sessionId);
        if (session is null)
            return NotFound(new { error = "Session not found" });

        var token = GenerateTokenBase64Url(32);
        var now = DateTime.UtcNow;
        var expires = now.AddSeconds(session.RotationSeconds);

        var rec = new TokenRecord
        {
            Token = token,
            SessionId = sessionId,
            IssuedAtUtc = now,
            ExpiresAtUtc = expires
        };

        _db.TokenRecords.Add(rec);
        _db.SaveChanges();

        var qrUrl = $"{Request.Scheme}://{Request.Host}/a/{token}";

        return Ok(new
        {
            token,
            expiresAtUtc = expires,
            qrUrl
        });
    }

    // 3) Public validate endpoint (normal QR scanners open this URL)
    [HttpGet("a/{token}")]
    public IActionResult Validate([FromRoute] string token)
    {
        var now = DateTime.UtcNow;

        ContentResult Page(string title, string message, string tokenValue, string? hint = null)
        {
            var openInAppLink = $"ictproject://scan?token={Uri.EscapeDataString(tokenValue)}";

            var html = $@"
    <!doctype html>
    <html lang=""en"">
        <head>
            <meta charset=""utf-8"" />
            <meta name=""viewport"" content=""width=device-width, initial-scale=1"" />
            <title>{title}</title>
                <style>
                    body {{ font-family: system-ui, Arial, sans-serif; margin: 0; padding: 0; background: #0b0f19; color: #e8eefc; }}
                    .wrap {{ max-width: 720px; margin: 0 auto; padding: 28px; }}
                    .card {{ background: #111827; border: 1px solid #22304a; border-radius: 16px; padding: 20px; box-shadow: 0 10px 30px rgba(0,0,0,.35); }}
                    .title {{ font-size: 22px; font-weight: 700; margin: 0 0 8px; }}
                    .msg {{ font-size: 16px; line-height: 1.5; margin: 0 0 14px; opacity: .95; }}
                    .hint {{ font-size: 13px; opacity: .75; margin-top: 10px; }}
                    .btns {{ display: flex; gap: 10px; margin-top: 18px; flex-wrap: wrap; }}
                    a.btn {{ text-decoration: none; padding: 12px 14px; border-radius: 12px; display: inline-block; font-weight: 650; }}
                    .primary {{ background: #3b82f6; color: white; }}
                    .secondary {{ background: #1f2937; color: #e8eefc; border: 1px solid #334155; }}
                    code {{ background: rgba(255,255,255,.08); padding: 2px 6px; border-radius: 8px; }}
                </style>
        </head>
        <body>
            <div class=""wrap"">
                <div class=""card"">
                    <p class=""title"">{title}</p>
                    <p class=""msg"">{message}</p>

                <div class=""btns"">
                    <a class=""btn primary"" href=""{openInAppLink}"">Open in App</a>

                    <a class=""btn secondary"" href=""#""
                        onclick=""navigator.clipboard.writeText('{tokenValue}'); alert('Token copied'); return false;"">
                        Copy Token
                    </a>

                    <a class=""btn secondary"" href=""#""
                        onclick=""fetch('/api/security/report', {{
                        method: 'POST',
                        headers: {{'Content-Type':'application/json'}},
                        body: JSON.stringify({{ token: '{tokenValue}', reason: 'MANUAL_REPORT' }})
                        }}).then(() => alert('Incident reported')); return false;"">
                        Report Suspicious QR
                    </a>
                </div>

                <p class=""hint"">
                    Token: <code>{tokenValue}</code>
                </p>

                    {(hint is null ? "" : $@"<p class=""hint"">{hint}</p>")}
                </div>
            </div>
        </body>
    </html>";

            return Content(html, "text/html");
        }

        IActionResult RedirectOrPage(string? url, Func<ContentResult> fallbackPage)
        {
            if (!string.IsNullOrWhiteSpace(url))
                return Redirect(url);

            return fallbackPage();
        }

        var rec = _db.TokenRecords.FirstOrDefault(t => t.Token == token);
        if (rec is null)
        {
            LogScan(token, null, "UNKNOWN");
            _db.SaveChanges();
            return Page("❌ Invalid QR", "This QR code is not recognised by the system. It may be tampered or not issued by the university.", token,
                "Ask your lecturer for the official QR and try again.");
        }

        var session = _db.Sessions.FirstOrDefault(s => s.Id == rec.SessionId);
        if (session is null)
        {
            LogScan(token, rec.SessionId, "UNKNOWN_SESSION");
            _db.SaveChanges();
            return Page("❌ Invalid QR", "This QR code is linked to an unknown session. It may be tampered.", token);
        }

        if (now < session.ValidFromUtc || now > session.ValidToUtc)
        {
            _db.SaveChanges();
            return RedirectOrPage(
                session.OutsideWindowRedirectUrl,
                () => Page("🚫 Outside attendance window",
                    $"This QR is only valid between {session.ValidFromUtc:u} and {session.ValidToUtc:u} (UTC).", token,
                    "If you're early/late, wait for the lecturer to open the attendance window.")
            );
        }

        if (now > rec.ExpiresAtUtc)
        {
            _db.SaveChanges();
            return RedirectOrPage(
                session.ExpiredRedirectUrl,
                () => Page("⏰ QR expired",
                    $"This QR token has expired. Please rescan the latest QR shown by the lecturer.", token,
                    "Dynamic QR codes rotate to prevent screenshot reuse.")
            );
        }

        LogScan(token, session.Id, "VALID");
        _db.SaveChanges();
        return RedirectOrPage(
            session.SuccessRedirectUrl,
            () => Page("✅ QR valid",
                $"This QR is valid for: {session.Name}. Open the app to complete check-in.", token)
        );
    }

    //check in requests

    public record CheckInRequest(string Token);

    [Authorize(Roles = "Student")]
    [HttpPost("api/attendance/checkin")]
    public IActionResult CheckIn([FromBody] CheckInRequest req)
    {
        var now = DateTime.UtcNow;

        var studentId = GetStudentId();
        if (string.IsNullOrWhiteSpace(studentId))
            return Unauthorized(new { result = "UNAUTHORISED", reason = "Missing student identity" });

        if (string.IsNullOrWhiteSpace(req.Token))
            return BadRequest(new { result = "BAD_REQUEST", reason = "Token is required" });

        var rec = _db.TokenRecords.FirstOrDefault(t => t.Token == req.Token);
        if (rec is null)
        {
            LogScan(req.Token, null, "CHECKIN_UNKNOWN", studentId);
            _db.SaveChanges();
            return BadRequest(new { result = "UNKNOWN", reason = "Token not found" });
        }

        var session = _db.Sessions.FirstOrDefault(s => s.Id == rec.SessionId);
        if (session is null)
        {
            LogScan(req.Token, rec.SessionId, "CHECKIN_UNKNOWN_SESSION", studentId);
            _db.SaveChanges();
            return BadRequest(new { result = "UNKNOWN", reason = "Session not found" });
        }

        if (now < session.ValidFromUtc || now > session.ValidToUtc)
        {
            LogScan(req.Token, session.Id, "CHECKIN_OUTSIDE_WINDOW", studentId);
            _db.SaveChanges();
            return BadRequest(new { result = "OUTSIDE_WINDOW", reason = "Not within allowed time window" });
        }

        if (now > rec.ExpiresAtUtc)
        {
            LogScan(req.Token, session.Id, "CHECKIN_EXPIRED", studentId);
            _db.SaveChanges();
            return BadRequest(new { result = "EXPIRED", reason = "Token expired" });
        }

        var exists = _db.AttendanceRecords.Any(a => a.SessionId == session.Id && a.StudentId == studentId);
        if (exists)
        {
            LogScan(req.Token, session.Id, "CHECKIN_DUP", studentId);
            _db.SaveChanges();
            return Ok(new { result = "DUPLICATE", reason = "Student already checked in" });
        }

        _db.AttendanceRecords.Add(new AttendanceRecord
        {
            SessionId = session.Id,
            StudentId = studentId,
            CheckedInAtUtc = now
        });

        LogScan(req.Token, session.Id, "CHECKIN_OK", studentId);
        _db.SaveChanges();

        return Ok(new
        {
            result = "CHECKED_IN",
            studentId,
            sessionId = session.Id,
            sessionName = session.Name,
            checkedInAtUtc = now
        });
    }

    // report endpoints

    public record ReportIncidentRequest(string Token, string Reason);

    [HttpPost("api/security/report")]
    public IActionResult ReportIncident([FromBody] ReportIncidentRequest req)
    {
        Guid? sessionId = null;

        var rec = _db.TokenRecords.FirstOrDefault(t => t.Token == req.Token);
        if (rec is not null)
            sessionId = rec.SessionId;

        _db.SecurityIncidents.Add(new SecurityIncident
        {
            Token = req.Token,
            SessionId = sessionId,
            Reason = req.Reason,
            Ip = HttpContext.Connection.RemoteIpAddress?.ToString(),
            UserAgent = Request.Headers.UserAgent.ToString()
        });

        _db.SaveChanges();
        return Ok(new { result = "REPORTED" });
    }

    //admin view for incidents

    [Authorize(Roles = "Admin")]
    [HttpGet("api/security/incidents")]
    public IActionResult GetIncidents()
    {
        return Ok(_db.SecurityIncidents
        .OrderByDescending(x => x.ReportedAtUtc)
        .Take(200)
        .ToList());
    }

    private string? GetStudentId()
    {
        return User.FindFirstValue(ClaimTypes.NameIdentifier);
    }

    private static string GenerateTokenBase64Url(int bytes)
    {
        var data = RandomNumberGenerator.GetBytes(bytes);
        var b64 = Convert.ToBase64String(data);
        return b64.Replace("+", "-").Replace("/", "_").Replace("=", "");
    }

    private void LogScan(string token, Guid? sessionId, string result, string? studentId = null)
    {
        _db.ScanEvents.Add(new ScanEvent
        {
            Token = token,
            SessionId = sessionId,
            Result = result,
            StudentId = studentId,
            ScannedAtUtc = DateTime.UtcNow,
            UserAgent = Request.Headers.UserAgent.ToString(),
            Ip = HttpContext.Connection.RemoteIpAddress?.ToString()
        });
    }


    public record CreateSessionRequest(
        string Name,
        DateTime ValidFromUtc,
        DateTime ValidToUtc,
        int RotationSeconds,
        string? SuccessRedirectUrl,
        string? ExpiredRedirectUrl,
        string? OutsideWindowRedirectUrl,
        string? InvalidRedirectUrl
        );



    //sessions

    public class Session
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = "";
        public DateTime ValidFromUtc { get; set; }
        public DateTime ValidToUtc { get; set; }
        public int RotationSeconds { get; set; }
        public string? SuccessRedirectUrl { get; set; }
        public string? ExpiredRedirectUrl { get; set; }
        public string? OutsideWindowRedirectUrl { get; set; }
        public string? InvalidRedirectUrl { get; set; }
    }

    public class TokenRecord
    {
        public string Token { get; set; } = "";
        public Guid SessionId { get; set; }
        public DateTime IssuedAtUtc { get; set; }
        public DateTime ExpiresAtUtc { get; set; }
    }

    //Attendance
    public class AttendanceRecord
    {
        public Guid SessionId { get; set; }
        public string StudentId { get; set; } = "";
        public DateTime CheckedInAtUtc { get; set; }
    }

    //scan events

    public class ScanEvent
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Token { get; set; } = "";
        public Guid? SessionId { get; set; }
        public DateTime ScannedAtUtc { get; set; } = DateTime.UtcNow;
        public string Result { get; set; } = ""; // VALID/EXPIRED/OUTSIDE_WINDOW/UNKNOWN/CHECKIN_OK/CHECKIN_DUP
        public string? StudentId { get; set; }
        public string? UserAgent { get; set; }
        public string? Ip { get; set; }
    }

    //security incidents

    public class SecurityIncident
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Token { get; set; } = "";
        public Guid? SessionId { get; set; }
        public string Reason { get; set; } = ""; // EXPIRED, UNKNOWN, OUTSIDE_WINDOW
        public DateTime ReportedAtUtc { get; set; } = DateTime.UtcNow;
        public string? Ip { get; set; }
        public string? UserAgent { get; set; }
    }

    //Admin view data endpoints
    [Authorize(Roles = "Lecturer,Admin")]
    [HttpGet("api/sessions/{sessionId:guid}/attendance")]
    public IActionResult GetAttendance([FromRoute] Guid sessionId)
    {
        return Ok(_db.AttendanceRecords
        .Where(x => x.SessionId == sessionId)
        .OrderBy(x => x.CheckedInAtUtc)
        .ToList());
    }

    [Authorize(Roles = "Lecturer,Admin")]
    [HttpGet("api/scans")]
    public IActionResult GetScans()
    {
        return Ok(_db.ScanEvents
        .OrderByDescending(x => x.ScannedAtUtc)
        .Take(200)
        .ToList());
    }


}

