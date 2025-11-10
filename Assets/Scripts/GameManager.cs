using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    public GameObject cube;
    public GameObject sunLight;
    // Start is called before the first frame update
    public float dayLenth = 60000f;
    public float timeOfDay = 0;
    void Start()
    {
        if(cube == null)
            cube = GameObject.Find("SkyBox");

        if (sunLight == null)
            sunLight = GameObject.Find("SunLight");
    }

    // Update is called once per frame
    void Update()
    {
        timeOfDay += Time.deltaTime;
        if(timeOfDay > dayLenth) timeOfDay -= dayLenth;

        float angle = (timeOfDay / dayLenth) * 360f;
        Vector3 sunDir = Quaternion.Euler(angle, 0, 0) * (-Vector3.forward);

        float sunIntensity = Mathf.Max(0, Mathf.Sin(2 * timeOfDay * Mathf.PI / dayLenth));

        cube.GetComponent<Renderer>().material.SetVector("_SunDir", sunDir);
        cube.GetComponent<Renderer>().material.SetFloat("_SunIntensity", sunIntensity);

        sunLight.GetComponent<Light>().transform.rotation = Quaternion.Euler(angle, 0, 0);
        sunLight.GetComponent<Light>().intensity = sunIntensity;

    }
}
