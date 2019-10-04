class Cycle {
  int x;
  int y;
  int Width;
  int Height;
  float period;
  String label;
  color c;
  float epsilon;
  
  Cycle(int a, int b, int c, int d, float e, String f) {
    x = a;
    y = b;
    Width = c;
    Height = d;
    period = e;
    label = f;
  }
  
  void rotate90(int canvasHeight) {
    int t = this.y;
    this.y = this.x;
    this.x = canvasHeight - (t+this.Height);
    t = this.Width;
    this.Width = this.Height;
    this.Height = t;
  }
  
  float calculateCyclePos(int syncYear, int year, int month, int day, int hour, int minute) {
    float numDays = (year - syncYear) * 365;
    
    if(month==1) numDays = numDays + day;
    else if(month==2) numDays = numDays + day + 31;
    else if(month==3) numDays = numDays + day + 59;
    else if(month==4) numDays = numDays + day + 90;
    else if(month==5) numDays = numDays + day + 120;
    else if(month==6) numDays = numDays + day + 151;
    else if(month==7) numDays = numDays + day + 181;
    else if(month==8) numDays = numDays + day + 212;
    else if(month==9) numDays = numDays + day + 243;
    else if(month==10) numDays = numDays + day + 273;
    else if(month==11) numDays = numDays + day + 304;
    else numDays = numDays + day + 334;
    
    int leapYear = (year - syncYear)/4;
    if(year%4==0 && month>=3) leapYear++;
    numDays = numDays + leapYear;
    numDays = numDays + ((hour*60)+minute)*1.0/1440.0;
    
    float cyclePos = (numDays/this.period) - floor(numDays/this.period);
    cyclePos = cyclePos*2;
    if(cyclePos>1) cyclePos = map(cyclePos, 1, 2, 1, 0);
    cyclePos = map(cyclePos, 0, 1, -0.5, 0.5);
    return cyclePos;
  }
  
  void updateColor(int hour, float cyclePos) {
    colorMode(HSB, 1440, 50, 50);
    this.c = color((hour*60)+minute()+(150*cyclePos), 22+this.epsilon, 36+this.epsilon);
  }
  
  boolean isMouseOver(int a, int b) {
    return(this.x<=a && a<(this.x+this.Width) && this.y<=b && b<(this.y+this.Height));
  }
  
  void showLabel(int canvasWidth, int canvasHeight) {
    noStroke();
    fill(215, 50);
    rect(0, 0, canvasWidth, canvasHeight);
    textAlign(LEFT);
    float Width = textWidth(this.label);
    int xOffset = round((canvasWidth - Width)/2.0);
    fill(255, 255);
    text(this.label, xOffset, round(canvasHeight/2.5));
  }
  
  void drawCycle() {
    noStroke();
    fill(this.c);
    rect(this.x, this.y, this.Width, this.Height);
  }
}