// this is a really straightforward effect that just reverses the order of the samples it receives
// it doesn't sound like how you think ;-)
class BonerEffect implements AudioEffect
{
  void process(float[] samp)
  {
    // sanity check for multiplier value
    if((multiplier < 0) || (multiplier > 1)){
      multiplier = 1;
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
  
