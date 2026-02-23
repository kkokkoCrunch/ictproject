using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ictproject.Migrations
{
    /// <inheritdoc />
    public partial class AddSessionRedirectUrls : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ExpiredRedirectUrl",
                table: "Sessions",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "InvalidRedirectUrl",
                table: "Sessions",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "OutsideWindowRedirectUrl",
                table: "Sessions",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SuccessRedirectUrl",
                table: "Sessions",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ExpiredRedirectUrl",
                table: "Sessions");

            migrationBuilder.DropColumn(
                name: "InvalidRedirectUrl",
                table: "Sessions");

            migrationBuilder.DropColumn(
                name: "OutsideWindowRedirectUrl",
                table: "Sessions");

            migrationBuilder.DropColumn(
                name: "SuccessRedirectUrl",
                table: "Sessions");
        }
    }
}
