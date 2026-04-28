using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ictproject.Migrations
{
    /// <inheritdoc />
    public partial class AddHybridTicketingFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "EmailError",
                table: "SecurityIncidents",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "EmailSentAtUtc",
                table: "SecurityIncidents",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "EmailStatus",
                table: "SecurityIncidents",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ExternalSyncError",
                table: "SecurityIncidents",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ExternalSyncStatus",
                table: "SecurityIncidents",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ExternalSystem",
                table: "SecurityIncidents",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ExternalTicketId",
                table: "SecurityIncidents",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ExternalTicketNumber",
                table: "SecurityIncidents",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "EmailError",
                table: "SecurityIncidents");

            migrationBuilder.DropColumn(
                name: "EmailSentAtUtc",
                table: "SecurityIncidents");

            migrationBuilder.DropColumn(
                name: "EmailStatus",
                table: "SecurityIncidents");

            migrationBuilder.DropColumn(
                name: "ExternalSyncError",
                table: "SecurityIncidents");

            migrationBuilder.DropColumn(
                name: "ExternalSyncStatus",
                table: "SecurityIncidents");

            migrationBuilder.DropColumn(
                name: "ExternalSystem",
                table: "SecurityIncidents");

            migrationBuilder.DropColumn(
                name: "ExternalTicketId",
                table: "SecurityIncidents");

            migrationBuilder.DropColumn(
                name: "ExternalTicketNumber",
                table: "SecurityIncidents");
        }
    }
}
