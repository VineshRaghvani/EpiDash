using EpiDash.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace EpiDash.Api.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        // This tells EF Core to create a table called "AirQualityRecords"
        public DbSet<AirQualityRecord> AirQualityRecords { get; set; }
    }
}