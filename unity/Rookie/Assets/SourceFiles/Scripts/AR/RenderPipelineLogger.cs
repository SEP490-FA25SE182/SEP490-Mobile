using UnityEngine;
using UnityEngine.Rendering;

public class RenderPipelineLogger : MonoBehaviour
{
    void Awake()
    {
        Debug.Log("[RenderPipelineLogger] Awake");
    }

    private System.Collections.IEnumerator Start()
    {
        while (true)
        {
            var currentPipeline = GraphicsSettings.currentRenderPipeline;
            var urpLit = Shader.Find("Universal Render Pipeline/Lit");

            Debug.Log(
                $"[RenderPipelineLogger] " +
                $"PipelineAsset={(currentPipeline != null ? currentPipeline.name : "NULL")}, " +
                $"URP/Lit shader={(urpLit != null ? urpLit.name : "NOT FOUND")}, " +
                $"supported={(urpLit != null && urpLit.isSupported)}"
            );

            yield return new WaitForSeconds(5f);
        }
    }
}

