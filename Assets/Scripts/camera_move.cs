using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class camera_move : MonoBehaviour
{
    // Start is called before the first frame update
    public Transform target;   // ½ÇÉ«
    public Transform targetHead;
    public Transform targetHair;
    public GameObject cube;
    public float distance = 5f;
    public float height = 2f;
    public float sensitivity = 2f;

    private float yaw = 0f;
    private float pitch = 20f;

    void Start()
    {
        Cursor.lockState = CursorLockMode.Locked; 
        Cursor.visible = false;
        cube = GameObject.Find("SkyBox");
    }

    void LateUpdate()
    {
        float mouseX = Input.GetAxis("Mouse X") * sensitivity;
        float mouseY = Input.GetAxis("Mouse Y") * sensitivity;

        yaw += mouseX;
        pitch -= mouseY;
        pitch = Mathf.Clamp(pitch, -20f, 85f); 

        Quaternion rotation = Quaternion.Euler(pitch, yaw, 0);
        Quaternion rotCharacter = Quaternion.Euler(0, yaw, 0);
        Quaternion rotHead = Quaternion.Euler(pitch, 0, 0);

        Vector3 offset = rotation * new Vector3(0, 0, -distance);
        transform.position = target.position + Vector3.up * height + offset;

        transform.LookAt(target.position + Vector3.up * height);
        cube.transform.position = transform.position;
        target.rotation = rotCharacter;
        targetHead.rotation = rotHead;
        targetHair.rotation = rotHead;
    }
}
