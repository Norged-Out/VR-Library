using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using System.Runtime.InteropServices.WindowsRuntime;
using Unity.Mathematics;
//using UnityEditor;
//using UnityEditor.Build.Reporting;
using UnityEngine;
using VRM;

public class PerlinNoiseGenerator : MonoBehaviour
{
    public int scale = 16;
    public int size = 8;
    private int[] perm = new int[512];
    public float baseFrequency = 1.0f;
    public float persistence = 0.5f;
    public float lacunarity = 2.0f;
    // using this formula to obtain smoother noise
    float Location(float t)
    {
        return t * t * t * (t * (t * 6 - 15) + 10);
    }

    // linear interpolation function to get the noise value between vertex
    float Lerp(float a, float b, float t)
    {
        return a + (b - a) * t;
    }

    // a faster implementtation for perlin noise
    float Grad(int hash, float x, float y, float z)
    {
        int h = hash & 15;
        float u = h < 8 ? x : y;
        float v = h < 4 ? y : (h == 12 || h == 14 ? x : z);
        return ((h & 1) == 0 ? u  : -u) + ((h & 2) == 0 ? v : -v);
    }

    // assigning each grid point a hash value to obtain the grad
    void PermGen()
    {
        //standard perlin noise permutation table from wikipedia
        int[] permutation = { 151, 160, 137,  91,  90,  15, 131,  13, 201,  95,  96,  53, 194, 233,   7, 225,
                      140,  36, 103,  30,  69, 142,   8,  99,  37, 240,  21,  10,  23, 190,   6, 148,
                      247, 120, 234,  75,   0,  26, 197,  62,  94, 252, 219, 203, 117,  35,  11,  32,
                       57, 177,  33,  88, 237, 149,  56,  87, 174,  20, 125, 136, 171, 168,  68, 175,
                       74, 165,  71, 134, 139,  48,  27, 166,  77, 146, 158, 231,  83, 111, 229, 122,
                       60, 211, 133, 230, 220, 105,  92,  41,  55,  46, 245,  40, 244, 102, 143,  54,
                       65,  25,  63, 161,   1, 216,  80,  73, 209,  76, 132, 187, 208,  89,  18, 169,
                      200, 196, 135, 130, 116, 188, 159,  86, 164, 100, 109, 198, 173, 186,   3,  64,
                       52, 217, 226, 250, 124, 123,   5, 202,  38, 147, 118, 126, 255,  82,  85, 212,
                      207, 206,  59, 227,  47,  16,  58,  17, 182, 189,  28,  42, 223, 183, 170, 213,
                      119, 248, 152,   2,  44, 154, 163,  70, 221, 153, 101, 155, 167,  43, 172,   9,
                      129,  22,  39, 253,  19,  98, 108, 110,  79, 113, 224, 232, 178, 185, 112, 104,
                      218, 246,  97, 228, 251,  34, 242, 193, 238, 210, 144,  12, 191, 179, 162, 241,
                       81,  51, 145, 235, 249,  14, 239, 107,  49, 192, 214,  31, 181, 199, 106, 157,
                      184,  84, 204, 176, 115, 121,  50,  45, 127,   4, 150, 254, 138, 236, 205,  93,
                      222, 114,  67,  29,  24,  72, 243, 141, 128, 195,  78,  66, 215,  61, 156, 180 };

        //duplicate the table to avoid out of bounds
        for (int i = 0; i < 256; i++)
        {
            perm[i] = permutation[i];
            perm[256 + i] = permutation[i];
        }
    }

    //main process to generate perlin niose
    float PerlinNoise3D(float x, float y, float z)
    {
        int X = (int)Mathf.Floor(x) & 255;
        int Y = (int)Mathf.Floor(y) & 255;
        int Z = (int)Mathf.Floor(z) & 255;

        x -= Mathf.Floor(x);
        y -= Mathf.Floor(y);
        z -= Mathf.Floor(z);

        float u = Location(x);
        float v = Location(y);
        float w = Location(z);

        int A = (perm[X] + Y);
        int AA = (perm[A] + Z);
        int AB = (perm[A + 1] + Z);
        int B = (perm[X + 1] + Y);
        int BA = (perm[B] + Z);
        int BB = (perm[B + 1] + Z);

        float res = Lerp(
            Lerp(Lerp(Grad(perm[AA], x, y, z),Grad(perm[BA], x-1, y, z), u),
                 Lerp(Grad(perm[AB], x, y-1, z), Grad(perm[BB], x-1, y-1, z), u), v),
            Lerp(Lerp(Grad(perm[AA+1], x, y, z-1), Grad(perm[BA+1], x-1, y, z-1), u),
                 Lerp(Grad(perm[AB+1], x, y-1, z-1), Grad(perm[BB+1], x-1, y-1, z-1), u), v),w
            );
        return (res + 1.0f) * 0.5f;
    }

    float fBm(float x, float y, float z, int octaves, float baseFreq, float persistence, float lacunarity)
    {
        float sum = 0f;
        float amp = 1f;
        float freq = baseFreq;
        float maxAmp = 0f;

        for (int i = 0; i < octaves; i++)
        {
            sum += amp * PerlinNoise3D(x * freq, y * freq, z * freq);
            maxAmp += amp;

            freq *= lacunarity;
            amp *= persistence;
        }

        return sum / maxAmp; 
    }

    // the noise is merely required to generate at the initialization of the game
    void Start()
    {
        PermGen();
        int length = size * scale;
        Texture3D perlinNoise = new Texture3D(length, length, length, TextureFormat.RGBA32, false);
        Color[] colors = new Color[length * length * length];
        int index = 0;
        for (int z = 0; z < length; z++)
            for(int y = 0; y < length; y++)
                for(int x = 0; x < length; x++, index++)
                {
                    float u = (float)x / scale;
                    float v = (float)y / scale;
                    float w = (float)z / scale;

                    float val = fBm(u, v, w, 5, baseFrequency, persistence, lacunarity);

                    colors[index] = new Color(val, val, val, 1.0f);
                }
        perlinNoise.SetPixels(colors);
        perlinNoise.Apply();
        //AssetDatabase.CreateAsset(perlinNoise, "Assets/PeilinNoise3D.asset");
        //AssetDatabase.SaveAssets();

        Debug.Log("Perlin Noise 3D is successfully created.");
    }

}
