using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using NetsimStokAPI.Models;

namespace NetsimStokAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IConfiguration _config;

    // Demo kullanıcıları — gerçek projede veritabanından/Netsim'den gelir.
    private static readonly Dictionary<string, string> Kullanicilar = new()
    {
        ["ahmet"] = "1234",
        ["demo"] = "demo",
    };

    public AuthController(IConfiguration config) => _config = config;

    [HttpPost("login")]
    public ActionResult<LoginYanit> Login([FromBody] LoginIstek istek)
    {
        if (!Kullanicilar.TryGetValue(istek.KullaniciAdi.ToLowerInvariant(), out var sifre)
            || sifre != istek.Sifre)
        {
            return Unauthorized("Kullanıcı adı veya şifre hatalı");
        }

        var jwt = _config.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var sonTarih = DateTime.UtcNow.AddMinutes(double.Parse(jwt["ExpireMinutes"] ?? "480"));

        var token = new JwtSecurityToken(
            issuer: jwt["Issuer"],
            audience: jwt["Audience"],
            claims: new[]
            {
                new Claim(ClaimTypes.Name, istek.KullaniciAdi),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            },
            expires: sonTarih,
            signingCredentials: creds);

        return Ok(new LoginYanit
        {
            Token = new JwtSecurityTokenHandler().WriteToken(token),
            GecerlilikSonu = sonTarih,
            KullaniciAdi = istek.KullaniciAdi,
        });
    }
}