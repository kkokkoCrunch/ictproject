using Microsoft.EntityFrameworkCore;
using ictproject.Controllers;

namespace ictproject.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<SecureQrController.Session> Sessions => Set<SecureQrController.Session>();
    public DbSet<SecureQrController.TokenRecord> TokenRecords => Set<SecureQrController.TokenRecord>();
    public DbSet<SecureQrController.AttendanceRecord> AttendanceRecords => Set<SecureQrController.AttendanceRecord>();
    public DbSet<SecureQrController.SecurityIncident> SecurityIncidents => Set<SecureQrController.SecurityIncident>();
    public DbSet<SecureQrController.ScanEvent> ScanEvents => Set<SecureQrController.ScanEvent>();


    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<SecureQrController.Session>().HasKey(x => x.Id);
        modelBuilder.Entity<SecureQrController.TokenRecord>().HasKey(x => x.Token);
        modelBuilder.Entity<SecureQrController.SecurityIncident>().HasKey(x => x.Id);
        modelBuilder.Entity<SecureQrController.ScanEvent>().HasKey(x => x.Id);

        // Prevent duplicates per session+student
        modelBuilder.Entity<SecureQrController.AttendanceRecord>()
            .HasKey(x => new { x.SessionId, x.StudentId });

        base.OnModelCreating(modelBuilder);
    }
}
