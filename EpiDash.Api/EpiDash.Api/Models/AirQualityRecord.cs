namespace EpiDash.Api.Models
{
    public class AirQualityRecord
    { 
        public int Id { get; set; } // Primary Key
        public required string LocationName { get; set; }
        public double AirQualityIndex { get; set; }
        public double Pm25Level { get; set; } // Particulate matter (e.g., wildfire smoke)
        public DateTime RecordDate { get; set; } = DateTime.UtcNow;
    }
}
