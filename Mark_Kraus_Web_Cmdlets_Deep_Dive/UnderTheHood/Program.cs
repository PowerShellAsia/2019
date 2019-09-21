`using System;
using System.Net.Http;

namespace UnderTheHood
{
    class Program
    {
        static void Main(string[] args)
        {
            Uri uri;
            try
            {
              uri = new Uri(args[0]);
            }
            catch (Exception e)
            {
              throw new ArgumentException("Invalid URI.", e);
            }

            Console.WriteLine($"GET {uri} with 0-byte payload");
            Console.WriteLine("------------------------------");

            var handler = new HttpClientHandler();
            var client = new HttpClient(handler);

            handler.AllowAutoRedirect = true;

            var request = new HttpRequestMessage(HttpMethod.Get, uri);

            var result = client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead).GetAwaiter().GetResult();

            var content = result.Content.ReadAsStringAsync().GetAwaiter().GetResult();

            Console.WriteLine(content);

        }
    }
}
