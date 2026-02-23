using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ictproject.Migrations
{
    /// <inheritdoc />
    public partial class AddStudentIdToScanEvents : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "StudentId",
                table: "ScanEvents",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "StudentId",
                table: "ScanEvents");
        }
    }
}
