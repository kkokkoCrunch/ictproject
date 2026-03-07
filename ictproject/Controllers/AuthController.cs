using ictproject.Data;
using ictproject.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace ictproject.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly AppDbContext _db;

    public AuthController(IConfiguration config, AppDbContext db)
    {
        _config = config;
        _db = db;
    }

    public record LoginRequest(string Username, string Password);

    [HttpPost("login")]
    public IActionResult Login([FromBody] LoginRequest req)
    {
        var user = _db.Users.SingleOrDefault(x => x.Username == req.Username);

        if (user == null || !BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            return Unauthorized(new { error = "Invalid username or password" });

        var jwt = _config.GetSection("Jwt");
        var key = jwt["Key"]!;
        var issuer = jwt["Issuer"]!;
        var audience = jwt["Audience"]!;

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Username),
            new Claim(ClaimTypes.Role, user.Role)
        };

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
        var creds = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddHours(6),
            signingCredentials: creds
        );

        return Ok(new
        {
            accessToken = new JwtSecurityTokenHandler().WriteToken(token),
            tokenType = "Bearer",
            role = user.Role,
            username = user.Username
        });
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("register")]
    public IActionResult Register([FromBody] RegisterRequest req)
    {
        // NEW: password length validation
        if (req.Password.Length < 8)
            return BadRequest(new { error = "Password must be at least 8 characters long" });

        if (_db.Users.Any(u => u.Username == req.Username))
            return BadRequest(new { error = "Username already exists" });

        var user = new User
        {
            Username = req.Username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password),
            Role = req.Role
        };

        _db.Users.Add(user);
        _db.SaveChanges();

        return Ok(new
        {
            message = "User created",
            username = user.Username,
            role = user.Role
        });
    }

    public record RegisterRequest(string Username, string Password, string Role);
}