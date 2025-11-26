using System;
using System.Collections.Generic;

[Serializable]
public class ARSceneWithItemsResponse
{
    public string sceneId;
    public MarkerDTO marker;
    public List<ARItemDTO> items;
    public List<Asset3DDTO> assets;
}

[Serializable]
public class MarkerDTO
{
    public string markerId;
    public string markerCode;
    public string imageUrl;
    public float physicalWidthM; // chiều rộng thực tế của marker (mét)
    public string markerType;
}

[Serializable]
public class ARItemDTO
{
    public string asset3DId;
    public int orderIndex;

    public float posX;
    public float posY;
    public float posZ;

    public float rotX;
    public float rotY;
    public float rotZ;

    public float scaleX = 1f;
    public float scaleY = 1f;
    public float scaleZ = 1f;
}

[Serializable]
public class Asset3DDTO
{
    public string asset3DId;
    public string assetUrl;    // có thể là https:// hoặc gs://
    public string fileName;
    public string format;      // GLB/FBX/OBJ (ưu tiên GLB)
    public int polycount;
    public float scale = 1f;      // optional
    public long fileSize;
}

[Serializable]
public class QuizResultMessage
{
    public string type = "quiz_result";
    public string quizId;
    public int score;
    public int number;
    public int coin;
    public bool isComplete;
    public bool isReward;
}