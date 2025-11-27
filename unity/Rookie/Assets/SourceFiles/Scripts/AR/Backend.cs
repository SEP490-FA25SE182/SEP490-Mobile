using System.Threading.Tasks;
using UnityEngine.Networking;
using UnityEngine;

public static class Backend
{
    public static async Task<ARSceneWithItemsResponse> FetchSceneByMarkerId(string markerId)
    {
        var baseUrl = FlutterBridge.LatestInput.backendBase.TrimEnd('/');
        var url = $"{baseUrl}/api/rookie/ar-scenes/by-marker-id/{UnityWebRequest.EscapeURL(markerId)}";

        using var req = UnityWebRequest.Get(url);
        var op = req.SendWebRequest();
        while (!op.isDone) await System.Threading.Tasks.Task.Yield();

        if (req.result != UnityWebRequest.Result.Success)
            throw new System.Exception($"Fetch scene failed: {req.error}");

        return JsonUtility.FromJson<ARSceneWithItemsResponse>(req.downloadHandler.text);
    }
}

