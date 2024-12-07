using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;

namespace FaceCrimPenguin.Controllers {
    [ApiController]
    [Route("api/[controller]")]

    public class ImageController : ControllerBase {
        [HttpPost("predict")]
        [Consumes("multipart/form-data")]

        public IActionResult PredictImage( IFormFile file) {
            try {
                var filePath = Path.GetTempFileName();
                using (var stream = new FileStream(filePath, FileMode.Create)) {
                    file.CopyTo(stream);
                }

                // string homePath = Environment.GetEnvironmentVariable("HOME");
                // string azureHomePath = Path.Combine(homePath, "site", "wwwroot", "predict", "predict.py");
                var scriptPath = Path.Combine(Directory.GetCurrentDirectory(), "predict", "predict.py");

                var start = new ProcessStartInfo {
                    FileName = "python",
                    Arguments = $"{scriptPath} {filePath}",
                    RedirectStandardOutput = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (var process = Process.Start(start)) {
#pragma warning disable CS8602 // Dereference of a possibly null reference.
                    using (var reader = process.StandardOutput) {
                        var result = reader.ReadToEnd();
                        return Ok(new { Prediction = result.Trim()});
                    }
#pragma warning restore CS8602 // Dereference of a possibly null reference.
                }
            }
            catch (Exception e) {
                return BadRequest(e.Message);
            }
        }
    }
}
