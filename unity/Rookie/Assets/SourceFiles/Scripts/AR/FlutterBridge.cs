using UnityEngine;
using FlutterUnityIntegration;   // cái này bạn đang có sẵn từ Unity package

[System.Serializable]
public class MarkerInput
{
    public string markerId;     
    public string backendBase;
}

public class FlutterBridge : MonoBehaviour
{
    public static MarkerInput LatestInput { get; private set; }

    public async void SetMarkerJson(string json)
    {
        LatestInput = JsonUtility.FromJson<MarkerInput>(json);
        Debug.Log($"[FlutterBridge] Received marker json: {json}");

        var runner = FindObjectOfType<ARSceneRunner>();
        if (runner == null)
        {
            Debug.LogError("[FlutterBridge] ARSceneRunner not found in scene");
            return;
        }

        await runner.StartWithInput(LatestInput);
        UnityMessageManager.Instance.SendMessageToFlutter("SceneReady");
    }
}

