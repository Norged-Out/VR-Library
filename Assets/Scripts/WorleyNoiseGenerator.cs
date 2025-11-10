using UnityEngine;
using Unity.Mathematics;
using UnityEditor;

public class WorleyNoiseGenerator : MonoBehaviour
{
    public int size = 8;                // 基础块数
    public int scale = 16;              // 每块分辨率
    public float baseFrequency = 1.0f;  // 起始频率
    public float persistence = 0.5f;    // 振幅衰减
    public float lacunarity = 2.0f;     // 频率增长
    public int octaves = 4;             // 叠加层数

    // 随机特征点
    float3 RandomFeature(int3 cell)
    {
        uint h = (uint)(cell.x * 73856093 ^ cell.y * 19349663 ^ cell.z * 83492791);
        h ^= (h >> 13);
        h *= 1274126177;
        return new float3(
            (h & 0xFF) / 255.0f,
            ((h >> 8) & 0xFF) / 255.0f,
            ((h >> 16) & 0xFF) / 255.0f
        );
    }

    // Worley 距离函数
    float WorleyNoise3D(float3 pos)
    {
        int3 cellBase = (int3)math.floor(pos);
        float minDistance = 99999.0f;
        for (int k = -1; k <= 1; k++)
            for (int j = -1; j <= 1; j++)
                for (int i = -1; i <= 1; i++)
                {
                    int3 cell = cellBase + new int3(i, j, k);
                    float3 feature = cell + RandomFeature(cell);
                    float distance = math.distance(feature, pos);
                    minDistance = math.min(minDistance, distance);
                }
        return minDistance;
    }

    // 分形 Worley fbm
    float WorleyFBM(float3 pos)
    {
        float sum = 0.0f;
        float amplitude = 1.0f;
        float frequency = baseFrequency;
        float norm = 0.0f;

        for (int o = 0; o < octaves; o++)
        {
            float val = WorleyNoise3D(pos * frequency);
            sum += val * amplitude;

            norm += amplitude;
            amplitude *= persistence;
            frequency *= lacunarity;
        }

        return sum; // 归一化
    }

    void Start()
    {
        int length = size * scale;
        int index = 0;
        Texture3D worleyNoise = new Texture3D(length, length, length, TextureFormat.RGBA32, false);
        Color[] colors = new Color[length * length * length];

        for (int x = 0; x < length; x++)
            for (int y = 0; y < length; y++)
                for (int z = 0; z < length; z++, index++)
                {
                    float3 pos = new float3((float)x / scale, (float)y / scale, (float)z / scale);

                    // fbm worley 值
                    float val = WorleyFBM(pos);

                    // 存到灰度
                    colors[index] = new Color(1 - val, 1 - val, 1 - val, 1.0f);
                }

        worleyNoise.SetPixels(colors);
        worleyNoise.Apply();

#if UNITY_EDITOR
        AssetDatabase.CreateAsset(worleyNoise, "Assets/WorleyNoise_FBM.asset");
        AssetDatabase.SaveAssets();
#endif

        Debug.Log("FBM Worley Noise 3D Texture created.");
    }
}
