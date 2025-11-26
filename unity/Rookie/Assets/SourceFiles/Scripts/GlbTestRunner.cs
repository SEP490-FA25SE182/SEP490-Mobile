using System.Threading.Tasks;
using UnityEngine;

public class GlbTestRunner : MonoBehaviour
{
    public ContentLoader contentLoader;
    [TextArea] public string glbUrl;

    private async void Start()
    {
        if (contentLoader == null)
        {
            Debug.LogError("[GlbTestRunner] contentLoader is NULL");
            return;
        }

        if (string.IsNullOrWhiteSpace(glbUrl))
        {
            Debug.LogError("[GlbTestRunner] glbUrl is empty");
            return;
        }

        // Load GLB
        var go = await contentLoader.LoadGlb(glbUrl);
        if (go == null)
        {
            Debug.LogError("[GlbTestRunner] LoadGlb returned NULL");
            return;
        }

        // Đặt model ngay trước camera
        var cam = Camera.main;
        if (cam != null)
        {
            var t = go.transform;
            t.position = cam.transform.position + cam.transform.forward * 2f; // cách camera 2m
            t.rotation = Quaternion.identity;
            t.localScale = Vector3.one; // nếu thấy to/nhỏ quá thì chỉnh ở đây

            Debug.Log($"[GlbTestRunner] Spawned '{go.name}' in front of camera at {t.position}");
        }
        else
        {
            Debug.LogWarning("[GlbTestRunner] No Camera.main found, using world origin");
            go.transform.position = Vector3.zero;
        }
    }
}
