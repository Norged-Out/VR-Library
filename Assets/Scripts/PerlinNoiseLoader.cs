using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PerlinNoiseLoader : MonoBehaviour
{
    public Texture3D cloudTex;
    public GameObject gameObject;
    // Start is called before the first frame update
    void Start()
    {
        if (gameObject == null)
            gameObject = GameObject.Find("SkyBox");
        if (cloudTex == null)
            return;
        gameObject.GetComponent<Renderer>().material.SetTexture("_DensityErodeTex", cloudTex);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
