int globalWidth = 0;
int globalHeight = 0;
float[] cyclePeriods = new float[12];
String[] Labels = new String[12];
Cycle[] Cycles = (Cycle[])new Cycle[12];
PFont GillSans;

//calculate all subsets of the ratios
float[][] allSubsets(float[] ratios) {
  if(ratios.length==0){
    float[][] subsets = new float[1][0];
    return subsets;
  }
  else {
    float last = ratios[ratios.length-1];
    ratios = shorten(ratios);
    float[][] subsets = allSubsets(ratios);
    float[][] finalSubsets = new float[2*subsets.length][];
    for(int i=0; i<subsets.length; i++) {
      finalSubsets[2*i] = subsets[i];
      finalSubsets[(2*i)+1] = append(subsets[i], last);
    }
    return finalSubsets;
  }
}

//filters all subsets of cardinality lower than 2
ArrayList filterCardinality(float[][] subsets) {
  ArrayList filteredSubsets = new ArrayList();
  for(int i=0; i<subsets.length; i++) {
    if(subsets[i].length>=2) {
      FloatList subset = new FloatList(subsets[i]);
      filteredSubsets.add(subset);
    }
  }
  return filteredSubsets;
}

//calculate the width addition of a subset
int subsetWidth(float ratio, FloatList ratios) {
  float ratioSum = 1;
  for(int i=1; i<ratios.size(); i++) {
    ratioSum = ratioSum + (ratios.get(i)/ratios.get(0));
  }
  int a = round((globalHeight*1.0)/ratioSum);
  int b = round((ratios.get(0)*globalWidth*globalHeight)/(ratio*a));
  return b;
}

//filter ArrayList of subsets based on choice of subset
ArrayList filterSubsetSequence(FloatList subset, ArrayList subsets) {
  for(int i=0; i<subset.size(); i++) {
    IntList toRemove = new IntList();
    for(int j=0; j<subsets.size(); j++) {
      if(((FloatList)subsets.get(j)).hasValue(subset.get(i))) {
        int index = j - toRemove.size();
        toRemove.append(index);
      }
    }
    for(int j=0; j<toRemove.size(); j++) {
      subsets.remove(toRemove.get(j));
    }
  }
  return subsets;
}

//depth first search of subset sequence tree, calculating width addition at each step
ArrayList allSubsetSequences(ArrayList subsets) {
  if(subsets.size()==0) {
    return subsets;
  }
  else if(subsets.size()==1) {
    ArrayList subsetSeq = new ArrayList();
    subsetSeq.add(subsets);
    return subsetSeq;
  }
  else {
    ArrayList sequenceList = new ArrayList();
    for(int i=0; i<subsets.size(); i++) {
      FloatList subset = (FloatList)subsets.get(i);
      ArrayList temp = new ArrayList();
      for(int j=0; j<subsets.size(); j++) {
        temp.add((FloatList)subsets.get(j));
      }
      ArrayList newSubsets = filterSubsetSequence(subset, temp);
      ArrayList localSequenceList = allSubsetSequences(newSubsets);
      for(int j=0; j<localSequenceList.size(); j++) {
        ArrayList temp1 = new ArrayList();
        temp1.add(subset);
        temp1.addAll((ArrayList)localSequenceList.get(j));
        localSequenceList.set(j, temp1);
      }
      sequenceList.addAll(localSequenceList);
    }
    return sequenceList;
  }
}

//ranks subset sequences by some criteria, returns highest ranking subset sequence
int finalSequenceNumber(ArrayList widthLists) {
  int bestMetric = -1; int bestSequence = -1;
  for(int i=0; i<widthLists.size(); i++) {
    boolean ordered = true;
    for(int j=0; j<((IntList)widthLists.get(i)).size()-1; j++) {
      if(((IntList)widthLists.get(i)).get(j)<((IntList)widthLists.get(i)).get(j+1)) {
        ordered = false;
        break;
      }
    }
    if(ordered==false) continue;
    
    int metric = 0;
    for(int j=0; j<((IntList)widthLists.get(i)).size()-1; j++) {
      metric += pow((((IntList)widthLists.get(i)).get(j)-((IntList)widthLists.get(i)).get(j+1)), 2);
    }
    metric = round((metric * 1.0) / (((IntList)widthLists.get(i)).size()-1));
    metric = round(sqrt(metric));
    if(bestMetric==-1 && bestSequence==-1) {
      bestMetric = metric;
      bestSequence = i;
    }
    if(metric<bestMetric) {
      bestMetric = metric;
      bestSequence = i;
    }
  }
  return bestSequence;
}

//checks if a column of rectangles produce a suitable width to height ratio and then initializes them
void addColumn(float ratio, float[] ratios, int placeHolder) {
  float ratioSum = 1;
  for(int i=1; i<ratios.length; i++) {
    ratioSum = ratioSum + (ratios[i]/ratios[0]);
  }
  int a = round((globalHeight*1.0)/ratioSum);
  int b = round((ratios[0]*globalWidth*globalHeight)/(ratio*a));
  int index = 0;
  for(int i=0; i<cyclePeriods.length; i++) {
    if(ratios[0]==cyclePeriods[i]) index = i;
  }
  Cycles[placeHolder] = new Cycle(globalWidth, 0, b, a, ratios[0], Labels[index]);
  int hOffset = a;
  placeHolder++;
  for(int i=1; i<ratios.length-1; i++) {
    a = round((ratios[i]/ratios[0])*a);
    for(int j=0; j<cyclePeriods.length; j++) {
      if(ratios[i]==cyclePeriods[j]) index = j;
    }
    Cycles[placeHolder] = new Cycle(globalWidth, hOffset, b, a, ratios[i], Labels[index]);
    hOffset += a;
    placeHolder++;
  }
  for(int j=0; j<cyclePeriods.length; j++) {
    if(ratios[ratios.length-1]==cyclePeriods[j]) index = j;
  }
  Cycles[placeHolder] = new Cycle(globalWidth, hOffset, b, globalHeight-hOffset, ratios[ratios.length-1], Labels[index]);
  globalWidth += b;
}

void makeCanvas() {
  globalWidth = 500;
  globalHeight = 500;
  Cycles[0] = new Cycle(0, 0, globalWidth, globalHeight, cyclePeriods[0], Labels[0]);
  
  float[] temp = new float[cyclePeriods.length-1];
  for(int i=0; i<temp.length; i++) {
    temp[i] = cyclePeriods[i+1];
  }
  ArrayList subsets = filterCardinality(allSubsets(temp));
  ArrayList allSequences = allSubsetSequences(subsets);
  ArrayList widthLists = new ArrayList();
  for(int i=0; i<allSequences.size(); i++) {
    float ratio = cyclePeriods[0];
    IntList widths = new IntList();
    for(int j=0; j<((ArrayList)allSequences.get(i)).size(); j++) {
      widths.append(subsetWidth(ratio, (FloatList)((ArrayList)allSequences.get(i)).get(j)));
      for(int k=0; k<((FloatList)((ArrayList)allSequences.get(i)).get(j)).size(); k++) {
        ratio += ((FloatList)((ArrayList)allSequences.get(i)).get(j)).get(k);
      }
    }
    widthLists.add(widths);
  }
  
  int sequenceNum = finalSequenceNumber(widthLists);
  subsets = (ArrayList)allSequences.get(sequenceNum);
  float ratio = cyclePeriods[0];
  int placeHolder = 1;
  for(int i=0; i<subsets.size(); i++) {
    float[] ratios = ((FloatList)subsets.get(i)).array();
    addColumn(ratio, ratios, placeHolder);
    for(int j=0; j<ratios.length; j++) {
      ratio = ratio + ratios[j];
    }
    placeHolder += ratios.length;
    for(int j=0; j<placeHolder; j++) {
      Cycles[j].rotate90(globalHeight);
    }
    int t = globalWidth;
    globalWidth = globalHeight;
    globalHeight = t;
  }
  
  if(globalHeight>globalWidth) {
    for(int j=0; j<Cycles.length; j++) {
      Cycles[j].rotate90(globalHeight);
    }
    int t = globalWidth;
    globalWidth = globalHeight;
    globalHeight = t;
  }
  
  /*if(globalWidth>900 || globalHeight>900) {
    int bigSide;
    if(globalWidth>=globalHeight) bigSide = globalWidth;
    else bigSide = globalHeight;
    float multiplier = 900.0/bigSide;
    globalWidth = floor(globalWidth*multiplier);
    globalHeight = floor(globalHeight*multiplier);
    for(int i=0; i<Cycles.length; i++) {
      Cycles[i].x = floor(Cycles[i].x*multiplier);
      Cycles[i].y = floor(Cycles[i].y*multiplier);
      Cycles[i].Width = floor(Cycles[i].Width*multiplier);
      Cycles[i].Height = floor(Cycles[i].Height*multiplier);
    }
  }*/
}

int hour = hour();
int minute = minute();
int day = day();
int month = month();
int year = year();
int lastMinute = millis();
int syncYear = 2000;
float speed = 1.0;
int hueHour = 0;
int numKeyPressed = 0;
int drawHourFrame = -1;
int drawSpeedFrame = -1;
boolean drawInstructionFrame = true;

void setup() {
  size(100, 100);
  
  cyclePeriods[0] = 10752.9; Labels[0] = "Saturn Revolution";
  //cyclePeriods[1] = 5595.45; Labels[1] = "Lemmon Comet Period";
  cyclePeriods[1] = 4328.9; Labels[1] = "Jupiter Revolution";
  cyclePeriods[2] = 3836.15; Labels[2] = "Boattini Comet Period";
  cyclePeriods[3] = 3489.4; Labels[3] = "Kowal Comet Period";
  cyclePeriods[4] = 3120.75; Labels[4] = "Catalina Comet Period";
  //cyclePeriods[6] = 3036.8; Labels[6] = "Tenagra Comet Period";
  //cyclePeriods[7] = 2730.2; Labels[7] = "Christensen Comet Period";
  cyclePeriods[5] = 2686.4; Labels[5] = "Lagerkvist Comet Period";
  cyclePeriods[6] = 1981.95; Labels[6] = "Kowalski Comet Period";
  cyclePeriods[7] = 1401.6; Labels[7] = "Stattmayer Comet Period";
  cyclePeriods[8] = 1361.45; Labels[8] = "Meyer Comet Period";
  cyclePeriods[9] = 686.2; Labels[9] = "Mars Revolution";
  cyclePeriods[10] = 521.95; Labels[10] = "IRAS Comet Period";
  cyclePeriods[11] = 365.26; Labels[11] = "Earth Revolution";
  
  makeCanvas();
  Cycles[0].epsilon = 0;
  for(int i=1; i<Cycles.length; i++) {
    float epsilon = random((i-1)*0.5, i*0.5);
    int sign;
    if(i%2==1) sign = 1;
    else sign = -1;
    Cycles[i].epsilon = sign*epsilon;
  }
  surface.setSize(globalWidth, globalHeight);
  GillSans = createFont("GillSans", 24);
  textFont(GillSans);
}

void draw() {
  calculateTime();
  for(int i=0; i<Cycles.length; i++) {
    float cyclePos = Cycles[i].calculateCyclePos(syncYear, year, month, day, hour, minute);
    Cycles[i].updateColor((hour()+hueHour)%24, cyclePos);
    Cycles[i].drawCycle();
  }
  
  if(drawHourFrame>=0) {
    noStroke();
    fill(215, 50);
    rect(0, 0, globalWidth, globalHeight);
    textAlign(LEFT);
    String text;
    if(minute()<10 && (hour()+hueHour)%24<10) text = "0"+((hour()+hueHour)%24)+":0"+minute();
    else if(minute()<10 && (hour()+hueHour)%24>=10) text = ((hour()+hueHour)%24)+":0"+minute();
    else if(minute()>=10 && (hour()+hueHour)%24<10) text = "0"+((hour()+hueHour)%24)+":"+minute();
    else text = ((hour()+hueHour)%24)+":"+minute();
    float Width = textWidth(text);
    int xOffset = round((globalWidth - Width)/2.0);
    fill(255, 255);
    text(text, xOffset, round(globalHeight/2.5));
    drawHourFrame++;
    if(drawHourFrame>60) drawHourFrame = -1;
  }
  
  if(drawSpeedFrame>=0) {
    noStroke();
    fill(215, 50);
    rect(0, 0, globalWidth, globalHeight);
    textAlign(LEFT);
    String text = "x "+speed;
    float Width = textWidth(text);
    int xOffset = round((globalWidth - Width)/2.0);
    fill(255, 255);
    text(text, xOffset, round(globalHeight/2.5));
    drawSpeedFrame++;
    if(drawSpeedFrame>60) drawSpeedFrame = -1;
  }
  
  if(numKeyPressed%2==1 && drawHourFrame==-1 && drawSpeedFrame==-1) {
    for(int i=0; i<Cycles.length; i++) {
      if(Cycles[i].isMouseOver(mouseX, mouseY)) {
        Cycles[i].showLabel(globalWidth, globalHeight);
      }
    }
  }
  
  if(drawInstructionFrame==true) {
    openingInstructions();
  }
}

void keyPressed() {
  if(key=='l') numKeyPressed++;
  if(key=='f') {
    speed = speed*2;
    drawSpeedFrame = 0;
  }
  if(key=='s') {
    speed = speed/2;
    drawSpeedFrame = 0;
  }
  if(key=='h') {
    hueHour++;
    drawHourFrame = 0;
  }
  if(key=='g') {
    hueHour--;
    drawHourFrame = 0;
  }
  if(key=='o') {
    calculateOptimum();
    drawSpeedFrame = 0;
  }
  if(key=='p') {
    speed = 1.0;
    drawSpeedFrame = 0;
  }
  if(key==ENTER || key==RETURN) {
    drawInstructionFrame = false;
    GillSans = createFont("GillSans", 32);
    textFont(GillSans);
  }
  if(key=='z') {
    String filename = Cycles.length + "_Cycles_" + nf(((hour()+hueHour)%24), 2) + "00.png";
    saveFrame("frames/" + filename);
    println("Saved: " + filename); 
  }
}

void openingInstructions() {
  noStroke();
  fill(215, 50);
  rect(0, 0, globalWidth, globalHeight);
  
  String text1 = "This clock phases with the cosmos. Through the subtle shifts in hue, watch as the world unfolds in every widening asynchronicity.";
  String text2 = "To toggle the labels of the cosmic cycles:";
  String text3 = "Press 'l' and hover over the rectangles";
  String text4 = "To control the speed of this clock's journey through time:";
  String text5 = "Press 'f' or 's'";
  String text6 = "To reach the optimum speed for the human eye:";
  String text7 = "Press 'o' (and 'p' to undo)";
  String text8 = "To move forwards and backwards in increments of an hour:";
  String text9 = "Press 'h' and 'g' respectively";
  String text10 = "To capture a moment:";
  String text11 = "Press'z'";
  String text12 = "Press 'Enter' to proceed";
  
  fill(255, 255);
  textAlign(LEFT);
  text(text1, 50, 50, globalWidth-100, globalHeight-100);
  text(text2, 100, 200, globalWidth/2-100, globalHeight-200);
  text(text4, 100, 300, globalWidth/2-100, globalHeight-300);
  text(text6, 100, 400, globalWidth/2-100, globalHeight-400);
  text(text8, 100, 525, globalWidth/2-100, globalHeight-525);
  text(text10, 100, 625, globalWidth/2-100, globalHeight-625);
  
  textAlign(RIGHT);
  text(text3, globalWidth/2, 200, (globalWidth/2)-100, globalHeight-200);
  text(text5, globalWidth/2, 300, (globalWidth/2)-100, globalHeight-300);
  text(text7, globalWidth/2, 400, (globalWidth/2)-100, globalHeight-400);
  text(text9, globalWidth/2, 525, (globalWidth/2)-100, globalHeight-525);
  text(text11, globalWidth/2, 625, (globalWidth/2)-100, globalHeight-625);
  text(text12, globalWidth-50, globalHeight-50);
}

void findYearMonthAndDay(int dayIncrement) {
  int[] monthDays = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
  dayIncrement = dayIncrement - (monthDays[month-1] - day);
  if(dayIncrement<=0) day = monthDays[month-1] + dayIncrement;
  else {
    while(dayIncrement>0) {
      month = (month%12)+1;
      if(month==1) year++;
      if(year%4==0 && month==2) dayIncrement -= 29;
      else dayIncrement -= monthDays[month-1];
    }
    if(year%4==0 && month==2) day = 29 + dayIncrement;
    else day = monthDays[month-1] + dayIncrement;
  }
}

void calculateTime() {
  int offset = floor((millis()-lastMinute)*speed/60000);
  if(offset>=1) lastMinute = millis();
  minute += offset;
  if (minute>=60){ hour = hour+(minute/60); minute %= 60;}
  int dayIncrement = 0;
  if(hour>=24) {
    dayIncrement = hour/24; 
    hour %= 24;
  }
  findYearMonthAndDay(dayIncrement);
}

void calculateOptimum() {
  int median = floor(cyclePeriods.length/2);
  float optimalSeconds = 10.0;
  speed = 1440*(60/optimalSeconds)*cyclePeriods[median];
  //speed = 31536000.0;
}
