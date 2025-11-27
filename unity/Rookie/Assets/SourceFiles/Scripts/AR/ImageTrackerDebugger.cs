using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;
using System.Linq;

public class ImageTrackerDebugger : MonoBehaviour
{
    [SerializeField] private ARTrackedImageManager trackedImageManager;

    void OnEnable()
    {
        if (trackedImageManager == null)
            trackedImageManager = FindAnyObjectByType<ARTrackedImageManager>();

        if (trackedImageManager != null)
        {
            trackedImageManager.trackedImagesChanged += OnTrackedImagesChanged;
            Debug.Log("[ImageTracker] OnEnable, manager = " + trackedImageManager);
        }
        else
        {
            Debug.LogError("[ImageTracker] Không tìm thấy ARTrackedImageManager!");
        }
    }

    void OnDisable()
    {
        if (trackedImageManager != null)
            trackedImageManager.trackedImagesChanged -= OnTrackedImagesChanged;
    }

    void OnTrackedImagesChanged(ARTrackedImagesChangedEventArgs args)
    {
        foreach (var added in args.added)
            Debug.Log($"[ImageTracker] ADDED {added.referenceImage.name} state={added.trackingState}");

        foreach (var upd in args.updated)
            Debug.Log($"[ImageTracker] UPDATED {upd.referenceImage.name} state={upd.trackingState}");

        foreach (var rem in args.removed)
            Debug.Log($"[ImageTracker] REMOVED {rem.referenceImage.name}");
    }
}
