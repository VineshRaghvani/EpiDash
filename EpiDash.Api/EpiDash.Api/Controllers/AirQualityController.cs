using EpiDash.Api.Data;
using EpiDash.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EpiDash.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AirQualityController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        // This connects the controller to your database
        public AirQualityController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/AirQuality
        [HttpGet]
        public async Task<ActionResult<IEnumerable<AirQualityRecord>>> GetRecords()
        {
            // Fetches all records from the database
            return await _context.AirQualityRecords.ToListAsync();
        }

        // POST: api/AirQuality/sync/{city}
        [HttpPost("sync/{city}")]
        public async Task<ActionResult<AirQualityRecord>> SyncLiveCityData(string city)
        {
            double lat = 0;
            double lon = 0;
            string displayName = "";

            // 1. Match the requested city to its coordinates
            switch (city.ToLower())
            {
                case "calgary":
                    lat = 51.0447;
                    lon = -114.0719;
                    displayName = "Calgary (Live Open-Meteo)";
                    break;
                case "vancouver":
                    lat = 49.2827;
                    lon = -123.1207;
                    displayName = "Vancouver (Live Open-Meteo)";
                    break;
                case "edmonton":
                default:
                    lat = 53.5461;
                    lon = -113.4938;
                    displayName = "Edmonton (Live Open-Meteo)";
                    break;
            }

            // 2. Fetch the live data using the dynamic coordinates
            using var client = new HttpClient();
            var url = $"https://air-quality-api.open-meteo.com/v1/air-quality?latitude={lat}&longitude={lon}&current=us_aqi,pm2_5";

            var response = await client.GetAsync(url);
            if (!response.IsSuccessStatusCode) return BadRequest("Failed to fetch live data from external API.");

            var jsonResponse = await response.Content.ReadAsStringAsync();
            using var document = System.Text.Json.JsonDocument.Parse(jsonResponse);
            var current = document.RootElement.GetProperty("current");

            var liveAqi = current.GetProperty("us_aqi").GetDouble();
            var livePm25 = current.GetProperty("pm2_5").GetDouble();

            // 3. Delete all old records in the database
            var oldRecords = _context.AirQualityRecords.ToList();
            if (oldRecords.Any())
            {
                _context.AirQualityRecords.RemoveRange(oldRecords);
                await _context.SaveChangesAsync();
            }

            // 4. Create and save the new record
            var newRecord = new AirQualityRecord
            {
                LocationName = displayName,
                AirQualityIndex = liveAqi,
                Pm25Level = livePm25,
                RecordDate = DateTime.UtcNow
            };

            _context.AirQualityRecords.Add(newRecord);
            await _context.SaveChangesAsync();

            return Ok(newRecord);
        }
    }
}