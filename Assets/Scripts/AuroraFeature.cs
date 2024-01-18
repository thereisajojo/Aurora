using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public class AuroraSettings
{
    public Color TopColor = new Color(0.8f, 0f, 1f, 1f);
    public Color BottomColor = new Color(0f, 1f, 0.67f, 1f);
    [Range(-1, 1)] public float ColorFactor = 0f;
    public float Height = 0.4f;
    public float HeightOffset = 0.15f;
    public float LayerDistance = 6f;
    [Range(0, 1)] public float Intensity = 1f;
    [Range(-1, 1)] public float MoveSpeedX = 0f;
    [Range(-1, 1)] public float MoveSpeedY = 0f;
    [Range(-1, 1)] public float NoiseSpeed = 0.5f;
    public bool Reflect = false;

    public Vector4 Speed => new Vector4(MoveSpeedX, MoveSpeedY, NoiseSpeed, 0);
}

public class AuroraFeature : ScriptableRendererFeature
{
    public Material AuroraMat;
    public Mesh SkyMesh;
    public AuroraSettings AuroraSettings;

    AuroraRenderPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new AuroraRenderPass(RenderPassEvent.BeforeRenderingSkybox, AuroraMat, SkyMesh);

        if (isActive)
        {
            Shader.EnableKeyword("_SAMPLE_AURORA");
        }
        else
        {
            Shader.DisableKeyword("_SAMPLE_AURORA");
        }
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (ShouldAdd())
        {
            m_ScriptablePass.Setup(AuroraSettings);
            renderer.EnqueuePass(m_ScriptablePass);
        }
    }

    private bool ShouldAdd()
    {
        return AuroraMat != null && SkyMesh != null;
    }
}

internal class AuroraRenderPass : ScriptableRenderPass
{
    private Material m_Material;
    private Mesh m_SkyMesh;
    private AuroraSettings m_Settings;

    private static readonly int s_AuroraTextureId = Shader.PropertyToID("_AuroraTexture");

    // private static readonly int s_TopColorId = Shader.PropertyToID("_TopColor");
    // private static readonly int s_HorizonColorId = Shader.PropertyToID("_HorizonColor");
    // private static readonly int s_BottomColorId = Shader.PropertyToID("_BottomColor");
    // private static readonly int s_IntensityId = Shader.PropertyToID("_Intensity");
    // private static readonly int s_Exponent1Id = Shader.PropertyToID("_Exponent1");
    // private static readonly int s_Exponent2Id = Shader.PropertyToID("_Exponent2");
    // private static readonly int s_StarColorId = Shader.PropertyToID("_StarColor");
    // private static readonly int s_StarIntensityId = Shader.PropertyToID("_StarIntensity");
    // private static readonly int s_StarSpeedId = Shader.PropertyToID("_StarSpeed");
    private static readonly int s_AuroraHeightId = Shader.PropertyToID("_AuroraHeight");
    private static readonly int s_AuroraHeightOffsetId = Shader.PropertyToID("_AuroraHeightOffset");
    private static readonly int s_AuroraDistanceId = Shader.PropertyToID("_AuroraDistance");
    private static readonly int s_AuroraIntensityId = Shader.PropertyToID("_AuroraIntensity");
    private static readonly int s_AuroraSpeedId = Shader.PropertyToID("_AuroraSpeed");
    private static readonly int s_AuroraColFactorId = Shader.PropertyToID("_AuroraColFactor");
    private static readonly int s_AuroraTopColorId = Shader.PropertyToID("_AuroraTopColor");
    private static readonly int s_AuroraBottomColorId = Shader.PropertyToID("_AuroraBottomColor");

    public AuroraRenderPass(RenderPassEvent evt, Material mat, Mesh mesh)
    {
        renderPassEvent = evt;
        m_Material = mat;
        m_SkyMesh = mesh;
    }

    public void Setup(AuroraSettings settings)
    {
        m_Settings = settings;
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        // material property
        m_Material.SetFloat(s_AuroraHeightId, m_Settings.Height);
        m_Material.SetFloat(s_AuroraHeightOffsetId, m_Settings.HeightOffset);
        m_Material.SetFloat(s_AuroraDistanceId, m_Settings.LayerDistance);
        m_Material.SetFloat(s_AuroraIntensityId, m_Settings.Intensity);
        m_Material.SetFloat(s_AuroraColFactorId, m_Settings.ColorFactor);
        m_Material.SetVector(s_AuroraSpeedId, m_Settings.Speed);
        m_Material.SetColor(s_AuroraTopColorId, m_Settings.TopColor);
        m_Material.SetColor(s_AuroraBottomColorId, m_Settings.BottomColor);
        if (m_Settings.Reflect)
        {
            m_Material.EnableKeyword("_REFLECT_AURORA");
        }
        else
        {
            m_Material.DisableKeyword("_REFLECT_AURORA");
        }

        var des = renderingData.cameraData.cameraTargetDescriptor;
        des.graphicsFormat = GraphicsFormat.B8G8R8A8_UNorm;
        des.depthBufferBits = 0;
        des.width /= 3;
        des.height /= 3;
        cmd.GetTemporaryRT(s_AuroraTextureId, des, FilterMode.Bilinear);

        ConfigureTarget(s_AuroraTextureId);
        ConfigureClear(ClearFlag.All, Color.black);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        const float meshScale = 100f;

        Vector3 cameraPos = renderingData.cameraData.worldSpaceCameraPos;
        Quaternion quaternion = Quaternion.Euler(0, 0, 0);
        Vector3 scale = Vector3.one * meshScale;
        Matrix4x4 transMat = Matrix4x4.TRS(cameraPos, quaternion, scale);

        CommandBuffer cmd = CommandBufferPool.Get();
        cmd.DrawMesh(m_SkyMesh, transMat, m_Material, 0, 0);
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
        cmd.ReleaseTemporaryRT(s_AuroraTextureId);
    }
}