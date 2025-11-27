using System;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Networking;
using GLTFast;

public class ContentLoader : MonoBehaviour
{
    [Header("Optional root for spawned models")]
    public Transform contentRoot;

    // Shader fallback ưu tiên dùng
    private static readonly string[] FallbackShaderNames =
    {
        "Shader Graphs/glTF-pbrMetallicRoughness", // shader Graph của glTFast (URP)
        "Universal Render Pipeline/Lit"            // nếu trên không có
    };

    // ================== LOAD GLB ==================

    /// <summary>
    /// Load 1 GLB từ URL (http/https/gs://) và instantiate làm con của contentRoot (nếu có).
    /// Trả về root GameObject chứa model.
    /// </summary>
    public async Task<GameObject> LoadGlb(string srcUrl)
    {
        Debug.Log($"[ContentLoader] LoadGlb srcUrl={srcUrl}");

        if (string.IsNullOrWhiteSpace(srcUrl))
            throw new ArgumentException("[ContentLoader] LoadGlb: srcUrl is null or empty");

        // 1) Đổi gs:// -> https nếu cần
        var httpUrl = await ResolveUrlAsync(srcUrl);
        Debug.Log($"[ContentLoader] Resolved URL: {httpUrl}");

        // 2) Dùng GltfImport với material generator mặc định
        var import = new GltfImport();

        var loaded = await import.Load(httpUrl);
        if (!loaded)
            throw new Exception($"[ContentLoader] glTFast Load failed: {httpUrl}");

        // 3) Tạo root object chứa model
        var go = new GameObject($"GLB:{System.IO.Path.GetFileName(httpUrl)}");
        if (contentRoot != null)
            go.transform.SetParent(contentRoot, false);

        // 4) Instantiate scene từ glTF
        var instantiated = await import.InstantiateMainSceneAsync(go.transform);
        if (!instantiated)
            throw new Exception("[ContentLoader] InstantiateMainSceneAsync failed");

        // 5) Fix material null (tránh model hồng)
        FixNullMaterials(go);

        // 6) Log lại material sau khi fix
        DumpMaterials(go);

        return go;
    }

    // ================== FIX MATERIAL ==================

    /// <summary>
    /// Với mọi Renderer con, nếu material null hoặc shader null
    /// thì gán material mới dùng shader fallback.
    /// </summary>
    private void FixNullMaterials(GameObject root)
    {
        if (root == null)
        {
            Debug.LogError("[ContentLoader] FixNullMaterials: root is null");
            return;
        }

        var renderers = root.GetComponentsInChildren<Renderer>(true);
        if (renderers.Length == 0)
        {
            Debug.Log("[ContentLoader] FixNullMaterials: no renderers found");
            return;
        }

        // Tìm shader fallback
        Shader fallback = null;
        foreach (var name in FallbackShaderNames)
        {
            fallback = Shader.Find(name);
            if (fallback != null)
            {
                Debug.Log($"[ContentLoader] Using fallback shader: {fallback.name}");
                break;
            }
        }

        if (fallback == null)
        {
            Debug.LogError("[ContentLoader] FixNullMaterials: no fallback shader found. " +
                           "Check that glTF shader or URP/Lit is included in build.");
            return;
        }

        foreach (var r in renderers)
        {
            var mats = r.sharedMaterials;
            bool changed = false;

            for (int i = 0; i < mats.Length; i++)
            {
                if (mats[i] == null || mats[i].shader == null)
                {
                    var mat = new Material(fallback)
                    {
                        name = $"AutoMat_{fallback.name}"
                    };
                    mats[i] = mat;
                    changed = true;
                }
            }

            if (changed)
            {
                r.sharedMaterials = mats;
            }
        }
    }

    // ================== DEBUG MATERIAL ==================

    private void DumpMaterials(GameObject root)
    {
        if (root == null)
        {
            Debug.LogError("[ContentLoader] DumpMaterials: root is null");
            return;
        }

        var renderers = root.GetComponentsInChildren<Renderer>(true);
        Debug.Log($"[ContentLoader] DumpMaterials: renderers={renderers.Length}");

        foreach (var r in renderers)
        {
            var mats = r.sharedMaterials;
            for (int i = 0; i < mats.Length; i++)
            {
                var m = mats[i];
                Debug.Log(
                    $"[ContentLoader] Renderer={r.name}, mat[{i}]={m?.name ?? "NULL"}, shader={m?.shader?.name ?? "NULL"}");
            }
        }
    }

    // ================== URL RESOLVE ==================

    /// <summary>
    /// Trả về URL http/https thực tế (nếu là gs:// thì resolve bằng Firebase hoặc convert sang public GCS).
    /// </summary>
    private async Task<string> ResolveUrlAsync(string url)
    {
        if (string.IsNullOrWhiteSpace(url))
            throw new ArgumentException("Empty url");

        // Nếu đã là http/https thì dùng luôn
        if (!url.StartsWith("gs://", StringComparison.OrdinalIgnoreCase))
            return url;

#if FIREBASE_PRESENT
        try
        {
            var storage = Firebase.Storage.FirebaseStorage.DefaultInstance;
            var gsRef = storage.GetReferenceFromUrl(url);
            var dlUrl = await gsRef.GetDownloadUrlAsync();
            return dlUrl.ToString();
        }
        catch (Exception e)
        {
            Debug.LogWarning($"[ContentLoader] Firebase resolve failed, url={url}, err={e.Message}");
            throw;
        }
#else
        if (TryGsToGcsHttps(url, out var https))
            return https;

        throw new NotSupportedException(
            "[ContentLoader] URL gs:// yêu cầu Firebase SDK (FIREBASE_PRESENT) hoặc public bucket (GCS HTTPS).");
#endif
    }

    /// <summary>
    /// Chuyển gs://bucket/path -> https://storage.googleapis.com/bucket/path (public bucket).
    /// </summary>
    private static bool TryGsToGcsHttps(string gs, out string https)
    {
        https = null;
        if (!gs.StartsWith("gs://", StringComparison.OrdinalIgnoreCase))
            return false;

        var rest = gs.Substring("gs://".Length);
        var slash = rest.IndexOf('/');
        if (slash < 0) return false;

        var bucket = rest.Substring(0, slash);
        var path = rest.Substring(slash + 1);
        https = $"https://storage.googleapis.com/{bucket}/{UnityWebRequest.EscapeURL(path)}";
        return true;
    }
}
