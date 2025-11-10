using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WASDMove : MonoBehaviour
{
    public float speed = 5f;
    public float rotationSpeed = 10f;
    public Transform cameraTransform;
    public Camera mainCamera;
    public Animator animator;
    private Rigidbody rb;

    void Start()
    {
        rb = GetComponent<Rigidbody>();
        mainCamera = Camera.main;
        animator = GetComponent<Animator>();
        Physics.gravity = new Vector3(0, 10.0f, 0);
        rb.constraints = RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationY | RigidbodyConstraints.FreezeRotationZ;
        Cursor.lockState = CursorLockMode.Locked;
    }

    void FixedUpdate()
    {
        float h = Input.GetAxis("Horizontal"); // A/D
        float v = Input.GetAxis("Vertical");   // W/S
        Vector3 forward = transform.forward;
        Vector3 right = transform.right;

        Vector3 move = (v*forward + h*right).normalized;
        move = move * Time.fixedDeltaTime * speed;

        if (move.magnitude > 0.00001)
        {
            animator.SetBool("isWalking", true);
        }
        else {
            animator.SetBool("isWalking", false);
        }

            rb.MovePosition(rb.position + move);
        mainCamera.transform.position += move;
    }
}