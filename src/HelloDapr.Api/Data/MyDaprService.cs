using Dapr.Client;

namespace HelloDapr.Api.Data;

public class MyClass
{
	public string? Summary { get; set; }
}

public class MyDaprService
{
	private const string DaprConfigurationStore = "configuration";
	private readonly List<string> _configurationItems = new() { "Test" };

	private readonly ILogger _logger;
	private readonly DaprClient _daprClient;

	public MyDaprService(ILogger<MyDaprService> logger, DaprClient daprClient)
	{
		_logger = logger;
		_daprClient = daprClient;
	}

	public async Task<MyClass[]> GetWithUrlAsync()
	{
		var output = new List<string>();

		//string daprGrpcUrl = (Environment.GetEnvironmentVariable("DAPR_GRPC_ENDPOINT") ?? "http://127.0.0.1") + ":" + (Environment.GetEnvironmentVariable("DAPR_GRPC_PORT") ?? "50001");
		string daprHttpUrl = (Environment.GetEnvironmentVariable("DAPR_HTTP_ENDPOINT") ?? "http://127.0.0.1") + ":" + (Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3500");
		var httpClient = new HttpClient();
		httpClient.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
		foreach (string? link in _configurationItems.Select(item => $"{daprHttpUrl}/v1.0/configuration/{DaprConfigurationStore}/?key={item}"))
		{
			_logger.Log(LogLevel.Information, "Calling {link}", link);
			string response = await httpClient.GetStringAsync(link);
			output.Add($"Response {response}");
		}

		return await Task.FromResult(output.Select(o => new MyClass
		{
			Summary = o
		}).ToArray());

	}

	public async Task<MyClass[]> GetWithSdkAsync()
	{
		GetConfigurationResponse? config = await _daprClient.GetConfiguration(DaprConfigurationStore, _configurationItems);
		var output = ( from item in config.Items let cfg = System.Text.Json.JsonSerializer.Serialize(item.Value) select "Configuration for " + item.Key + ": " + cfg ).ToList();

		return await Task.FromResult(output.Select(o => new MyClass
		{
			Summary = o
		}).ToArray());
	}

}
