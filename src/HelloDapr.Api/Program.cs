using HelloDapr.Api.Data;


var builder = WebApplication.CreateBuilder(args);
builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();

//builder.Services.AddDaprClient(c => c.UseHttpEndpoint("http://host.docker.internal:3601").UseGrpcEndpoint("http://host.docker.internal:50002"));
builder.Services.AddDaprClient();
builder.Services.AddSingleton<MyDaprService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
	// The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
	app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();

app.UseRouting();

app.MapBlazorHub();
app.MapFallbackToPage("/_Host");

app.Run();
