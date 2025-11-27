using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;
using UnityEngine.Networking;
using System.Threading.Tasks;

public class RuntimeImageLoader : MonoBehaviour
{
    [SerializeField] ARTrackedImageManager imageManager;

    public async Task SetupMarkerFromUrl(string markerCode, string imageUrl, float physicalWidthM)
    {
        using var req = UnityWebRequestTexture.GetTexture(imageUrl);
        var op = req.SendWebRequest();
        while (!op.isDone) await Task.Yield();
        if (req.result != UnityWebRequest.Result.Success)
            throw new System.Exception($"Load marker image failed: {req.error}");

        var tex = DownloadHandlerTexture.GetContent(req);

        var mlib = imageManager.referenceLibrary as MutableRuntimeReferenceImageLibrary;
        if (mlib == null)
        {
            mlib = (MutableRuntimeReferenceImageLibrary)imageManager.CreateRuntimeLibrary();
            imageManager.referenceLibrary = mlib;
        }

        var job = mlib.ScheduleAddImageWithValidationJob(tex, markerCode, physicalWidthM);
        while (!job.jobHandle.IsCompleted) await Task.Yield();
        job.jobHandle.Complete();
        Debug.Log($"[RuntimeImageLoader] Added marker {markerCode} ({physicalWidthM} m)");
    }
}
