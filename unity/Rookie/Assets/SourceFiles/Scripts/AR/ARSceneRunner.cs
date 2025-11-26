using System;
using System.Linq;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

/// <summary>
/// Nhận MarkerInput từ Flutter, gọi backend lấy ARSceneWithItemsResponse,
/// đăng ký marker runtime và spawn GLB lên marker khi tracking.
/// </summary>
public class ARSceneRunner : MonoBehaviour
{
    [Header("Refs")]
    [SerializeField] ARTrackedImageManager imageManager;
    [SerializeField] RuntimeImageLoader loader;
    [SerializeField] ContentLoader content;

    [Header("Optional")]
    [Tooltip("Gốc thế giới AR (thường là XR Origin). Nếu null sẽ dùng transform của ImageManager.")]
    [SerializeField] Transform worldRoot;

    Transform anchor;                                       // điểm gắn model theo marker
    readonly Dictionary<string, GameObject> spawned = new();// asset3DId -> GameObject

    ARSceneWithItemsResponse data;
    MarkerInput currentInput;

    bool isSpawning = false;                                // tránh chạy EnsureSpawned trùng
    bool sceneReady = false;                                // scene đã load từ backend + đăng ký marker xong chưa
    bool hasSpawned = false;                                // đã spawn model lần nào chưa

    //================= UNITY LIFECYCLE =================

    void OnEnable()
    {
        if (imageManager != null)
            imageManager.trackedImagesChanged += OnChanged;
    }

    void OnDisable()
    {
        if (imageManager != null)
            imageManager.trackedImagesChanged -= OnChanged;
    }

    //================= PUBLIC API (gọi từ FlutterBridge) =================

    /// <summary>
    /// Gọi từ FlutterBridge khi mở AR cho 1 marker.
    /// </summary>
    public async Task StartWithInput(MarkerInput input)
    {
        Debug.Log("[ARSceneRunner] >>> StartWithInput BEGIN");

        sceneReady = false;
        hasSpawned = false;
        isSpawning = false;
        anchor = null;
        spawned.Clear();

        try
        {
            if (input == null)
            {
                Debug.LogError("[ARSceneRunner] StartWithInput: input is null");
                return;
            }

            if (string.IsNullOrEmpty(input.markerId))
            {
                Debug.LogError("[ARSceneRunner] StartWithInput: input.markerId is null or empty");
                return;
            }

            currentInput = input;
            Debug.Log($"[ARSceneRunner] FetchSceneByMarkerId markerId = {input.markerId}");

            // 1) Lấy scene theo markerId
            try
            {
                data = await Backend.FetchSceneByMarkerId(input.markerId);
                Debug.Log("[ARSceneRunner] FetchSceneByMarkerId OK");
            }
            catch (Exception ex)
            {
                Debug.LogError($"[ARSceneRunner] FetchSceneByMarkerId exception: {ex}");
                return;
            }

            if (data == null)
            {
                Debug.LogError("[ARSceneRunner] StartWithInput: data is null");
                return;
            }

            if (data.marker == null)
            {
                Debug.LogError("[ARSceneRunner] StartWithInput: data.marker is null");
                return;
            }

            Debug.Log($"[ARSceneRunner] Marker from backend: markerId={data.marker.markerId}, " +
                      $"img={data.marker.imageUrl}, width={data.marker.physicalWidthM}");

            // 2) Đăng ký image target runtime
            try
            {
                await loader.SetupMarkerFromUrl(
                    data.marker.markerId,   // dùng markerId làm name
                    data.marker.imageUrl,
                    data.marker.physicalWidthM
                );
                Debug.Log("[ARSceneRunner] SetupMarkerFromUrl OK");
            }
            catch (Exception ex)
            {
                Debug.LogError($"[ARSceneRunner] SetupMarkerFromUrl exception: {ex}");
                return;
            }

            if (imageManager == null)
            {
                Debug.LogError("[ARSceneRunner] StartWithInput: imageManager is null");
                return;
            }

            // Đảm bảo không double-subscribe
            imageManager.trackedImagesChanged -= OnChanged;
            imageManager.trackedImagesChanged += OnChanged;

            sceneReady = true;
            Debug.Log("[ARSceneRunner] >>> Setup done, sceneReady = TRUE, waiting for tracking...");
        }
        catch (Exception ex)
        {
            Debug.LogError($"[ARSceneRunner] >>> StartWithInput FATAL EXCEPTION: {ex}");
        }
    }

    //================= AR EVENTS =================

    void OnChanged(ARTrackedImagesChangedEventArgs e)
    {
        // Copy ra list riêng (không dùng trực tiếp collection nội bộ của ARFoundation)
        var imgs = new List<ARTrackedImage>();
        imgs.AddRange(e.added);
        imgs.AddRange(e.updated);

        _ = HandleTrackedImages(imgs);
    }

    async Task HandleTrackedImages(List<ARTrackedImage> imgs)
    {
        if (!sceneReady || data == null || data.marker == null)
        {
            Debug.Log($"[ARSceneRunner] HandleTrackedImages: scene not ready. " +
                      $"sceneReady={sceneReady}, dataNull={data == null}, markerNull={data?.marker == null}");
            return;
        }

        string expectedName = data.marker.markerId;

        foreach (var img in imgs)
        {
            var guid = img.referenceImage.guid;
            var name = img.referenceImage.name;
            var state = img.trackingState;

            Debug.Log($"[ARSceneRunner] OnChanged: guid={guid} name={name} state={state}");

            // Chỉ dùng đúng marker mà backend trả về
            if (!string.Equals(name, expectedName, StringComparison.Ordinal))
            {
                Debug.Log($"[ARSceneRunner] Ignore image name={name}, expected={expectedName}");
                continue;
            }

            // Khi None thì bỏ qua
            if (state == TrackingState.None)
                continue;

            // Tạo anchor nếu chưa có
            if (anchor == null)
            {
                var parent = worldRoot != null ? worldRoot : imageManager.transform;

                var goAnchor = new GameObject("MarkerAnchor");
                anchor = goAnchor.transform;
                anchor.SetParent(parent, false);
                anchor.SetPositionAndRotation(img.transform.position, img.transform.rotation);

                Debug.Log($"[ARSceneRunner] Created anchor at worldPos={anchor.position}");
            }
            else
            {
                // Cập nhật anchor theo marker
                anchor.SetPositionAndRotation(img.transform.position, img.transform.rotation);
            }

            // Nếu đang Tracking và chưa spawn model thì gọi EnsureSpawned
            if (state == TrackingState.Tracking && !hasSpawned && !isSpawning)
            {
                isSpawning = true;
                try
                {
                    await EnsureSpawned();
                    hasSpawned = true;
                }
                finally
                {
                    isSpawning = false;
                }
            }
        }
    }

    //================= INTERNAL =================

    async Task EnsureSpawned()
    {
        Debug.Log("[ARSceneRunner] EnsureSpawned: BEGIN");

        if (data == null)
        {
            Debug.LogError("[ARSceneRunner] EnsureSpawned: data is null (StartWithInput chưa chạy thành công?)");
            return;
        }

        if (data.items == null || data.items.Count == 0)
        {
            Debug.LogWarning("[ARSceneRunner] EnsureSpawned: data.items is null or empty");
            return;
        }

        if (data.assets == null || data.assets.Count == 0)
        {
            Debug.LogWarning("[ARSceneRunner] EnsureSpawned: data.assets is null or empty");
            return;
        }

        if (anchor == null)
        {
            Debug.LogError("[ARSceneRunner] EnsureSpawned: anchor is null, không thể gắn object");
            return;
        }

        var orderedItems = data.items.OrderBy(i => i.orderIndex).ToList();
        Debug.Log($"[ARSceneRunner] EnsureSpawned: processing {orderedItems.Count} items; currently spawned={spawned.Count}");

        for (int index = 0; index < orderedItems.Count; index++)
        {
            var it = orderedItems[index];

            if (it == null)
            {
                Debug.LogWarning($"[ARSceneRunner] Item #{index} is null, skip");
                continue;
            }

            var key = it.asset3DId;
            if (string.IsNullOrEmpty(key))
            {
                Debug.LogError($"[ARSceneRunner] Item #{index} có asset3dId null/empty, bỏ qua. Item = {JsonUtility.ToJson(it)}");
                continue;
            }

            if (spawned.ContainsKey(key))
            {
                Debug.Log($"[ARSceneRunner] Item #{index} asset3dId={key} đã spawn rồi, skip");
                continue;
            }

            var asset = data.assets.FirstOrDefault(a => a.asset3DId == key);
            if (asset == null)
            {
                Debug.LogError($"[ARSceneRunner] Không tìm thấy asset cho asset3dId={key}. Item={JsonUtility.ToJson(it)}");
                continue;
            }

            Debug.Log($"[ARSceneRunner] Loading asset asset3dId={key}, url={asset.assetUrl}");

            GameObject go = null;
            try
            {
                go = await content.LoadGlb(asset.assetUrl);
            }
            catch (Exception ex)
            {
                Debug.LogError($"[ARSceneRunner] LoadGlb exception, asset3dId={key}, url={asset.assetUrl}, ex={ex}");
                continue;
            }

            if (go == null)
            {
                Debug.LogError($"[ARSceneRunner] LoadGlb trả về null, asset3dId={key}, url={asset.assetUrl}");
                continue;
            }

            go.name = $"ARItem_{key}";
            go.transform.SetParent(anchor, false);

            // Transform từ DB
            Vector3 dbPos = new Vector3(it.posX, it.posY, it.posZ);
            Vector3 dbRot = new Vector3(it.rotX, it.rotY, it.rotZ);
            Vector3 dbScale = new Vector3(it.scaleX, it.scaleY, it.scaleZ);
            Debug.Log($"[ARSceneRunner] DB transform for {key}: pos={dbPos}, rot={dbRot}, scale={dbScale}");

            // Nếu scale = 0 hoặc quá nhỏ thì gán tạm và clamp
            float minScale = 0.05f;
            float maxScale = 1.5f;

            if (Mathf.Approximately(dbScale.x, 0)) dbScale.x = 0.2f;
            if (Mathf.Approximately(dbScale.y, 0)) dbScale.y = 0.2f;
            if (Mathf.Approximately(dbScale.z, 0)) dbScale.z = 0.2f;

            dbScale.x = Mathf.Clamp(dbScale.x, minScale, maxScale);
            dbScale.y = Mathf.Clamp(dbScale.y, minScale, maxScale);
            dbScale.z = Mathf.Clamp(dbScale.z, minScale, maxScale);

            // Nếu model bị bay quá xa marker (> 2m) thì kéo lại gần
            if (dbPos.magnitude > 2f)
            {
                dbPos = dbPos.normalized * 0.5f;
            }

            go.transform.localPosition = dbPos;
            go.transform.localEulerAngles = dbRot;
            go.transform.localScale = dbScale;

            spawned[key] = go;

            Debug.Log($"[ARSceneRunner] Spawned asset3dId={key} at localPos={go.transform.localPosition}, localScale={go.transform.localScale}");
        }

        Debug.Log($"[ARSceneRunner] EnsureSpawned finished. Total spawned={spawned.Count}");
    }
}
