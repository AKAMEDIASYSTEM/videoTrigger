//This effect manually fades out a player over time.
//It only exists becuase Minim doesn't support fading on my machine...wtf?!


class FaderEffect implements AudioEffect
{
  void process(float[] samp)
  {
    // sanity check for fade_Intensity value
    if((fade_Intensity < 0) || (fade_Intensity > 1)) {
      fade_Intensity = MULTIPLIER_DEFAULT;
    }
    float[] processed = new float[samp.length];
    for (int j = 0; j < samp.length; j++)
    {
      processed[j] = samp[j] * fade_Intensity;
    }
    // we have to copy the values back into samp for this to work
    arraycopy(processed, samp);
  }

  void process(float[] left, float[] right)
  {
    process(left);
    process(right);
  }
}

