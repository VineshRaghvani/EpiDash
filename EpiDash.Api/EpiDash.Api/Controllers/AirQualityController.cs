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

        // POST: api/AirQuality
        [HttpPost]
        public async Task<ActionResult<AirQualityRecord>> PostRecord(AirQualityRecord record)
        {
            // Adds a new record to the database
            _context.AirQualityRecords.Add(record);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetRecords), new { id = record.Id }, record);
        }
    }
}