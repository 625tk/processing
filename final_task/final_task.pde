import controlP5.*;

import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;

boolean is_sync = false;
final int SCREEN_WIDTH= 600;
final int SCREEN_HEIGHT=600;
final int PAD = 10;
int BAR_WIDTH=1;


int SIN_WAVE_NUM = 1;
SinWave[] sin_waves;

ControlP5 cp5;
Slider slider;
int slider_value=5;
boolean reset_flag = false;

void setup()
{
  size(600, 600, P3D);
  frameRate(60);
  cp5 = new ControlP5(this);
  slider = cp5.addSlider("SIN_WAVES", 1, 50, slider_value, 0, 10, 100, 10);
  slider.setLabelVisible(false);
  
  minim = new Minim(this);
  out = minim.getLineOut();

  SIN_WAVE_NUM = slider_value;
  BAR_WIDTH=(SCREEN_WIDTH-PAD*2)/SIN_WAVE_NUM;
  sin_waves = new SinWave[SIN_WAVE_NUM];
  for(int i = 0; i < SIN_WAVE_NUM; ++i){
    sin_waves[i] = new SinWave(i);
  }
}

void reset(){
  for(int i = 0; i < SIN_WAVE_NUM; ++i){
    sin_waves[i].unpatch();
  }
  SIN_WAVE_NUM = slider_value;
  BAR_WIDTH=(SCREEN_WIDTH-PAD*2)/SIN_WAVE_NUM;
  sin_waves = new SinWave[SIN_WAVE_NUM];
  for(int i = 0; i < SIN_WAVE_NUM; ++i){
    sin_waves[i] = new SinWave(i);
  }
}

void draw(){
  if(reset_flag){
    reset();
    reset_flag = false;
  }
  background(0);

  fill(255);
  text("waves: " + SIN_WAVE_NUM, 100, 20);
  if(is_sync){
    text(" synced!" , 300, 20);
  }
  
  stroke(255);
  for(int i = 0; i < SIN_WAVE_NUM; ++i){
    sin_waves[i].update(sin_waves[(i+SIN_WAVE_NUM-1)%SIN_WAVE_NUM].freq(), sin_waves[(i+1)%SIN_WAVE_NUM].freq());
  }

  for(int i = 0; i < SIN_WAVE_NUM; ++i){
    print(sin_waves[i].freq()+ " ");
    sin_waves[i].draw();
  }println("");

  is_sync = true;
  int sync_with = sin_waves[0].freq();
  for(int i = 1; i < SIN_WAVE_NUM; ++i){
    if(sync_with != sin_waves[i].freq()){
      is_sync = false;
      break;
    }
  }

  stroke(255);
  for(int i = 0; i < out.bufferSize() - 1; ++i){
    line(i, 70 + out.left.get(i) * 50, i + 1, 70 + out.left.get(i+1)* 50);
  }
}

class SinWave{
  Oscil       sound;
  int index;
  float ignore;
  
  SinWave(int ind){
    index = ind;
    float vol = 0.5f/(SIN_WAVE_NUM);
    int range = 500;
    ignore = random(0.5);
    ignore += 0.25f;
    
    sound = new Oscil( random(range), vol, Waves.SINE );
    sound.patch(out);
  }
  
  void unpatch(){
    sound.unpatch(out);
  }
  
  void draw(){
    fill(255);
    stroke(0);
    if( is_sync ){
      fill(127);
    }
    sound.frequency.getLastValues();
    rect( PAD + index * BAR_WIDTH, SCREEN_HEIGHT - freq(), BAR_WIDTH, SCREEN_HEIGHT);
  }
  
  void update(int freq_left, int freq_right){
    if(random(1) > ignore){
      int current = (int)sound.frequency.getLastValue();
      int target = current;

      if(freq_left > current && freq_right > current){
        target++;
      }else if(freq_left < current && freq_right < current){
        target--;
      }else if(!(freq_left == current && freq_right == current)){
        int r = (int)random(2);
        if(r < 0.20){
          target++;
        }else if(r > 0.80){
          target--;
        }
      }

      sound.setFrequency(target);
    }
  }
  int freq(){
    return (int)sound.frequency.getLastValue();
  }
}

void controlEvent(ControlEvent ce) {
  if (ce.getName() == "SIN_WAVES") {
    slider_value = (int)ce.getValue();
  }
  reset_flag = true;
}
