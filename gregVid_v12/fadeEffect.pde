//This effect manually fades out a player over time.
//It only exists becuase Minim doesn't support fading on my machine...wtf?!


class FaderEffect implements AudioEffect
{
  void process(float[] samp)
  {
    // sanity check for multiplier value
    if((multiplier < 0) || (multiplier > 1)) {
      multiplier = MULTIPLIER_DEFAULT;
    }
    float[] processed = new float[samp.length];
    for (int j = 0; j < samp.length; j++)
    {
      processed[j] = samp[j] * multiplier;
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

