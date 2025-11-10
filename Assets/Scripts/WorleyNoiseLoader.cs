using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WorleyNoiseLoader : MonoBehaviour
{
    public GameObject mObject;
    public Texture3D worleyTex;
    // Start is called before the first frame update
    void Start()
    {
        if (mObject == null)
            mObject = GameObject.Find("SkyBox");
        if (worleyTex == null)
            return;

        mObject.GetComponent<Renderer>().material.SetTexture(" _DensityNoiseTex", worleyTex);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
