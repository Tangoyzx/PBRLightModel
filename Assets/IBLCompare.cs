using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IBLCompare : MonoBehaviour {

	// Use this for initialization
	void Start () {
		for(var i = 0; i < 6; i++) {
			var childTransform = transform.Find("c" + i);
			Debug.Log("ccchild : " + childTransform);
			var renderer = childTransform.GetComponent<Renderer>();
			renderer.material.SetFloat("_Gloss", (float)i * 0.2f);
		}
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
