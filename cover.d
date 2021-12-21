// Written in the D programming language.

// Copyright: Coverify Systems Technology 2016
// License:   Distributed under the Boost Software License, Version 1.0.
//            (See accompanying file LICENSE_1_0.txt or copy at
//            http://www.boost.org/LICENSE_1_0.txt)
// Authors:   Puneet Goel <puneet@coverify.com>

module esdl.rand.cover;
import std.stdio;
// Coverage
//import esdl.rand.misc;

static string doParse(T)(string Bins){
  parser!T Parser = parser!T(Bins);
  return Parser.parse();
}

enum Type: bool {SINGLE, MULTIPLE};

struct parser (T){
  import std.conv;
  enum BinType: byte {SINGLE, DYNAMIC, STATIC};
  size_t srcCursor = 0;
  size_t outCursor = 0;
  size_t srcLine = 0;
  string outBuffer = "";
  string BINS;

  this(string bins){
    BINS = bins;
  }
  void fill(in string source) {
    //import std.stdio;
    //pragma(source);
    outBuffer ~= source;
  }
  void parseComma(){
    if(BINS[srcCursor] != ','){
      assert(false, "did not add comma in bins range at line " ~ srcLine.to!string);
    }
    ++srcCursor;
    parseSpace();
  }
  bool parseRangeType(){
    if(BINS[srcCursor] == ':'){
      ++ srcCursor;
      return true;
    }
    else if(BINS[srcCursor] == '.' && BINS[srcCursor+1] == '.'){
      srcCursor += 2;
      return false;
    }
    else{
      assert(false, "error in writing bins at line "~ srcLine.to!string ~ " " ~ BINS[srcCursor]);
    }
  }
  void parseCurlyOpen(){
    if(BINS[srcCursor] != '{'){
      assert(false);
    }
    ++ srcCursor;
  }
  void parseEqual(){
    if(BINS[srcCursor] != '='){
      assert(false);
    }
    ++ srcCursor;
  }
  size_t parseName(){
    auto start = srcCursor;
    while(BINS[srcCursor] != ' ' && BINS[srcCursor] != '=' && BINS[srcCursor] != '\n'&& BINS[srcCursor] != '\t' ){
      ++srcCursor;
    }
    return start;
  }
  BinType parseType(){
    parseSpace();
    if(BINS[srcCursor] == '['){
      srcCursor ++;
      parseSpace();
      if(BINS[srcCursor] == ']'){
        ++srcCursor;
        return BinType.DYNAMIC;
      }
      return BinType.STATIC;
    }
    else{
      return BinType.SINGLE;
    }
  }
  size_t parseLiteral() {
    size_t start = srcCursor;
    if(BINS[srcCursor] == '$'){
      ++srcCursor;
      return start;
    }
    // check for - sign
    if (BINS[srcCursor] == '-'){
      ++srcCursor;
    }
    // look for 0b or 0x
    if (srcCursor + 2 <= BINS.length &&
        BINS[srcCursor] == '0' &&
        (BINS[srcCursor+1] == 'x' ||
         BINS[srcCursor+1] == 'X')) { // hex numbers
      srcCursor += 2;
      while (srcCursor < BINS.length) {
        char c = BINS[srcCursor];
        if ((c >= '0' && c <= '9') ||
            (c >= 'a' && c <= 'f') ||
            (c >= 'A' && c <= 'F') ||
            (c == '_')) {
          ++srcCursor;
        }
        else {
          break;
        }
      }
    }
    else if (srcCursor + 2 <= BINS.length &&
        BINS[srcCursor] == '0' &&
        (BINS[srcCursor+1] == 'b' ||
         BINS[srcCursor+1] == 'B')) { // binary numbers
      srcCursor += 2;
      while (srcCursor < BINS.length) {
        char c = BINS[srcCursor];
        if ((c == '0' || c == '1' || c == '_')) {
          ++srcCursor;
        }
        else {
          break;
        }
      }
    }
    else {			// decimals
      while (srcCursor < BINS.length) {
        char c = BINS[srcCursor];
        if ((c >= '0' && c <= '9') ||
            (c == '_')) {
          ++srcCursor;
        }
        else {
          break;
        }
      }
    }
    if (srcCursor > start) {
      // Look for long/short specifier
      while (srcCursor < BINS.length) {
        char c = BINS[srcCursor];
        if (c == 'L' || c == 'u' ||  c == 'U') {
          ++srcCursor;
        }
        else {
          break;
        }
      }
    }
    return start;
  }
  void parseBinDeclaration(){
    parseSpace();
    if(BINS[srcCursor] != 'b' || BINS[srcCursor+1] != 'i' || BINS[srcCursor+2] != 'n' ||BINS[srcCursor+3] != 's'){
      assert(false, "error in writing bins at line " ~ srcLine.to!string);
    }
    srcCursor += 4;
    //return start;
  }
  size_t parseSpace() {
    size_t start = srcCursor;
    while (srcCursor < BINS.length) {
      auto srcTag = srcCursor;

      parseLineComment();
      parseBlockComment();
      parseNestedComment();
      parseWhiteSpace();

      if (srcCursor > srcTag) {
        continue;
      }
      else {
        break;
      }
    }
    return start;
  }
  size_t parseComment(){
    auto start = srcCursor;
    while (srcCursor < BINS.length) {
      auto srcTag = srcCursor;
      parseLineComment();
      parseBlockComment();
      parseNestedComment();
      if (srcCursor > srcTag) {
        continue;
      }
      else {
        break;
      }
    }
    return start;
  }
  size_t parseWhiteSpace() {
    auto start = srcCursor;
    while (srcCursor < BINS.length) {
      auto c = BINS[srcCursor];
      // eat up whitespaces
      if (c is '\n') ++srcLine;
      if (c is ' ' || c is '\n' || c is '\t' || c is '\r' || c is '\f') {
        ++srcCursor;
        continue;
      }
      else {
        break;
      }
    }
    return start;
  }

  size_t parseLineComment() {
    size_t start = srcCursor;
    if (srcCursor >= BINS.length - 2 ||
        BINS[srcCursor] != '/' || BINS[srcCursor+1] != '/') return start;
    else {
      srcCursor += 2;
      while (srcCursor < BINS.length) {
        if (BINS[srcCursor] == '\n') {
          break;
        }
        else {
          if (srcCursor == BINS.length) {
            // commment unterminated
            assert (false, "Line comment not terminated at line "~ srcLine.to!string);
          }
        }
        srcCursor += 1;
      }
      srcCursor += 1;
      return start;
    }
  }

  size_t parseBlockComment() {
    size_t start = srcCursor;
    if (srcCursor >= BINS.length - 2 ||
        BINS[srcCursor] != '/' || BINS[srcCursor+1] != '*') return start;
    else {
      srcCursor += 2;
      while (srcCursor < BINS.length - 1) {
        if (BINS[srcCursor] == '*' && BINS[srcCursor+1] == '/') {
          break;
        }
        else {
          if (srcCursor == BINS.length - 1) {
            // commment unterminated
            assert (false, "Block comment not terminated at line "~ srcLine.to!string);
          }
        }
        srcCursor += 1;
      }
      srcCursor += 2;
      return start;
    }
  }
  void parseBin(string BinType){
    size_t srcTag;
    while(true){
      if(BINS[srcCursor] == '['){
        ++srcCursor;
        parseSpace();
        srcTag = parseLiteral();
        string min;
        if(BINS[srcTag .. srcCursor] == "$"){
          min = T.max.stringof;
        }
        else{
          min = BINS[srcTag .. srcCursor];
        }
        //min = to!T(BINS[srcTag .. srcCursor]);
        parseSpace();
        bool isInclusive = parseRangeType();
        parseSpace();
        srcTag = parseLiteral();
        string max;
        if(BINS[srcTag .. srcCursor] == "$"){
          max = T.max.stringof;
        }
        else{
          max = BINS[srcTag .. srcCursor];
        }
        if(!isInclusive){
          max ~= "-1";
        }
        fill(BinType ~"[$-1].addRange(" ~ min ~ ", " ~ max ~ ");\n");
        parseSpace();
        if(BINS[srcCursor] != ']'){
          assert(false, "range not ended after two elements at line "~ srcLine.to!string);
        }
        ++srcCursor;
        parseSpace();
      }
      else{
        srcTag = parseLiteral();
        string val;
        if(BINS[srcTag .. srcCursor] == "$"){
          val = T.max.stringof;
        }
        else{
          val = BINS[srcTag .. srcCursor];
        }
        //makeBins ~= 
        fill(BinType ~ "[$-1].addRange(" ~ val ~ ");\n");
        parseSpace();
      }
      if(BINS[srcCursor] == '}'){
        break;
      }
      parseComma();
    }

  }
  size_t parseNestedComment() {
    size_t nesting = 0;
    size_t start = srcCursor;
    if (srcCursor >= BINS.length - 2 ||
        BINS[srcCursor] != '/' || BINS[srcCursor+1] != '+') return start;
    else {
      srcCursor += 2;
      while (srcCursor < BINS.length - 1) {
        if (BINS[srcCursor] == '/' && BINS[srcCursor+1] == '+') {
          nesting += 1;
          srcCursor += 1;
        }
        else if (BINS[srcCursor] == '+' && BINS[srcCursor+1] == '/') {
          if (nesting == 0) {
            break;
          }
          else {
            nesting -= 1;
            srcCursor += 1;
          }
        }
        srcCursor += 1;
        if (srcCursor >= BINS.length - 1) {
          // commment unterminated
          assert (false, "Block comment not terminated at line "~ srcLine.to!string);
        }
      }
      srcCursor += 2;
      return start;
    }
  }

  string parse(){
    parseSpace();
    while(srcCursor < BINS.length){
      parseBinDeclaration();
      BinType bintype = parseType();
      if(bintype == BinType.SINGLE){
        auto srcTag = parseName();
        string name = BINS[srcTag .. srcCursor];
        parseSpace();
        parseEqual();
        parseSpace();
        parseCurlyOpen();
        parseSpace();
        fill("_bins ~= Bin!T( \"" ~ name ~ "\");\n");
        parseBin("_bins");
      }
      else if(bintype == BinType.DYNAMIC) {
        parseSpace();
        auto srcTag = parseName();
        fill("_dbins ~= Bin!T( \"" ~ BINS[srcTag .. srcCursor] ~ "\");\n");
        parseSpace();
        parseEqual();
        parseSpace();
        parseCurlyOpen();
        parseSpace();
        parseBin("_dbins");
      }
      else {
        auto srcTag = parseLiteral();
        string arrSize = BINS[srcTag .. srcCursor];
        parseSpace();
        if(BINS[srcCursor] != ']'){
          assert(false, "error in writing bins at line "~ srcLine.to!string);
        }
        ++srcCursor;
        parseSpace();
        srcTag = parseName();
        fill("_sbins ~= Bin!T( \"" ~ BINS[srcTag .. srcCursor] ~ "\");\n");
        fill("_sbinsNum ~= " ~ arrSize ~ "; \n");
        parseSpace();
        parseEqual();
        parseSpace();
        parseCurlyOpen();
        parseSpace();
        parseBin("_sbins");
      }
      ++srcCursor;
      parseSpace();
      if(BINS[srcCursor] != ';'){
        import std.stdio;
        writeln("hello");
        assert(false, "';' expected, not found at line " ~ srcLine.to!string);
      }
      ++srcCursor;
      parseSpace();
    }
    return outBuffer;
  }
}


struct BinRange(T)
{
  this (T val){
    _min = val;
    _max = val;
  }
  this (T min, T max){
    _min = min;
    _max = max;
  }
  T _min;
  T _max;
};

struct Bin(T)
{
  string _name;
  uint _hits;
  BinRange!(T)[] _ranges;
  this(string name){
    _name = name;
    _hits = 0;
  }
  size_t binarySearch(T val){
    size_t left = 0, right = _ranges.length - 1, mid = 0;
    while (left <= right)
    {
      mid = (right + left) / 2;
      if (val == _ranges[mid]._max)
        break;
      if (val < _ranges[mid]._max){
        if(mid == 0){
          break;
        }
        right = mid - 1;
      }
      else if (val > _ranges[mid]._max)
        left = mid + 1;
    }
    if(_ranges[mid]._max < val){
      mid ++;
    }
    return mid;
  }
  void addRange(T val)
  {
    if(_ranges.length == 0){
      _ranges ~= BinRange!T(val);
    }
    auto pos = binarySearch(val);
    if(pos >= _ranges.length){
      _ranges ~= BinRange!T(val);
      return;
    }
    if(_ranges[pos]._min <= val){
      return;
    }
    _ranges = _ranges[0 .. pos] ~ BinRange!T(val) ~ _ranges[pos .. $];
  }
  string getName(){
    return _name;    
  }
  auto getRanges(){
    return _ranges;
  }

  void addRange(T min, T max)
  {
    assert(min <= max, "minimum value is greater than maximum in range");
    if(_ranges.length == 0){
      _ranges ~= BinRange!T(min, max);
    }
    auto pos1 = binarySearch(min);
    if(pos1 >= _ranges.length){
      _ranges ~= BinRange!T(min, max);
      return;
    }
    auto pos2 = binarySearch(max);
    if(_ranges[pos1]._min <= min){
      if(pos2 >= _ranges.length){
        auto temp = BinRange!T(_ranges[pos1]._min, max);
        _ranges.length = pos1;
        _ranges ~= temp;
      }
      else{
        if(pos1 == pos2){
          return;
        }
        if(_ranges[pos2]._min <= max){
          auto temp = BinRange!T(_ranges[pos1]._min, _ranges[pos2]._max);
          _ranges = _ranges[0 .. pos1] ~ temp ~ _ranges[pos2+1 .. $];
        }
        else{
          auto temp = BinRange!T(_ranges[pos1]._min, max);
          _ranges = _ranges[0 .. pos1] ~ temp ~ _ranges[pos2 .. $];
        }
      }
    }
    else{
      if(pos2 >= _ranges.length){
        auto temp = BinRange!T(min, max);
        _ranges.length = pos1;
        _ranges ~= temp;
      }
      else{
        if(_ranges[pos2]._min <= max){
          auto temp = BinRange!T(min, _ranges[pos2]._max);
          _ranges = _ranges[0 .. pos1] ~ temp ~ _ranges[pos2+1 .. $];
        }
        else{
          auto temp = BinRange!T(min, max);
          _ranges = _ranges[0 .. pos1] ~ temp ~ _ranges[pos2 .. $];
        }
      }
    }
  }

  string describe()
  {
    import std.conv;
    string s = "Name : " ~ _name ~ "\n";
    /* if(_type == Type.SINGLE){ */
    /*     s ~= "Single : \n"; */
    /*     return (s ~ to!string(_single) ~ "\n"); */
    /* } */
    /* s ~= "Multiple : \n"; */
    foreach (elem; _ranges)
    {
      s ~= to!string(elem._min) ~ ", " ~ to!string(elem._max) ~ "\n";
    }
    return s;
  }
  size_t count(){
    /* if(_type == Type.SINGLE){ */
    /*     return 1; */
    /* } */
    size_t c = 0;
    for(size_t i = 0; i < _ranges.length; i++){
      c += (1uL + _ranges[i]._max) - _ranges[i]._min;
    }
    return c;
  }
  void normalize(){
    for(size_t i = 0; i < _ranges.length-1; i++){
      assert(_ranges[i]._max < _ranges[i+1]._min && _ranges[i]._max >= _ranges[i]._min);
      if(_ranges[i]._max == _ranges[i+1]._min - 1){
        _ranges[i]._max = _ranges[i+1]._max;
        if(i+2 < _ranges.length){
          _ranges = _ranges[0 .. i+1] ~ _ranges[i+2 .. $];
        }
        else{
          _ranges = _ranges[0 .. i+1];
        }
      }
    }
  }
  bool checkHit(T val)
  {
    /* if(_type == Type.SINGLE){ */
    /*     return (val == _single); */
    /* } */
    ulong len = _ranges.length;
    if (val < _ranges[0]._min)
      return false;
    if (val > _ranges[$ - 1]._max)
      return false;
    ulong left = 0, right = len - 1;
    while (left <= right)
    {
      ulong mid = (right + left) / 2;
      if (val >= _ranges[mid]._min && val <= _ranges[mid]._max)
        return true;
      if (val < _ranges[mid]._min)
        right = mid - 1;
      else if (val > _ranges[mid]._max)
        left = mid + 1;
    }
    return false;
  }
};

string makeArray(size_t len, string type,string name){
  string s = type ~ " ";
  for(int i = 0; i < len; i++){
    s ~= "[]"; 
  }
  s ~= " " ~ name ~ ";";
  return s;
}

string crossSampleHelper(int n){
  import std.conv;
  string s = "bool [][] inst_hits_arr;\n";
  for(int i = 0; i < n; i++){
    s ~= "inst_hits_arr ~= coverPoints[" ~ i.to!string() ~ "].get_inst_hits();\n";
  }
  for(int i = 0; i < n; i++){
    s ~= "foreach(i_" ~ i.to!string() ~ ", is_hit_" ~ i.to!string() ~ "; inst_hits_arr[" ~ i.to!string() ~ "]){\n";
    s ~= "if(!is_hit_" ~ i.to!string() ~ ")\ncontinue;\n";
  }
  s ~= "_hits";
  for(int i = 0; i < n; i++){
    s ~= "[i_" ~ i.to!string() ~ "]"; 
  }
  s ~= "++;\n";
  s ~= "_inst_hits";
  for(int i = 0; i < n; i++){
    s ~= "[i_" ~ i.to!string() ~ "]"; 
  }
  s ~= " = true;\n";
  for(int i = 0; i < n; i++)
    s ~= "}\n";
  return s;
}

string arrayInitialising(int n, ulong [] bincnts) (string name){
  import std.conv;
  string s,tmp = name;
  for(int i = 0; i < n; i++){
    s ~= tmp ~ ".length = " ~ bincnts[i].to!string() ~ ";\n";
    tmp ~= "[" ~ i.to!string() ~ "]";
  }
  return s;
}

class Cross ( N... ): coverInterface{
  enum size_t len = N.length;
  mixin(makeArray(len, "uint", "_hits"));
  mixin(makeArray(len, "bool", "_inst_hits"));
  coverInterface [] coverPoints;
  this (){
    import std.traits: isIntegral;
    ulong [] bincnts;
    foreach (i , elem; N){
      static if (is (typeof(elem): coverInterface)){
        coverPoints ~= elem;
        bincnts ~= elem.getBins().length;
      }
      else {
        auto tmp = new CoverPoint!(elem)();
        coverPoints ~= tmp;
        bincnts ~= tmp.getBins().length;
      }
    }
    /* mixin(arrayInitialising!(len, bincnts)("_hits")); */
    /* mixin(arrayInitialising!(len, bincnts)("_inst_hits")); */
  }
  override void sample(){
    mixin(crossSampleHelper(N.length));
  }
  override double get_coverage(){
    return 0;

  }
  override double get_inst_coverage(){
    return 0;

  }
  override void start(){

  }
  override void stop(){

  }
  override bool [] get_inst_hits(){
    assert(false);
  }
}

interface coverInterface {
  void sample ();
  double get_coverage();
  double get_inst_coverage();
  void start();
  void stop();
  bool [] get_inst_hits();
  //double query();
  //double inst_query();
}

class CoverPoint(alias t, string BINS="") : coverInterface{
  import std.traits: isIntegral;
  //import esdl.data.bvec: isBitVector;
  alias T = typeof(t);

  static assert(isIntegral!T || isBitVector!T || is(T: bool),
      "Only integral, bitvec, or bool values can be covered."
      ~ " Unable to cover a value of type: " ~ T.stringof);
  T* _point; // = &t;
  //char[] outBuffer;
  string outBuffer;
  bool [] _inst_hits;
  this (){

    import std.stdio;
    static if (BINS != ""){
      mixin(doParse!T(BINS));
    }
    else {
      import std.conv;
      mixin(doParse!T("bins [32] a = {[" ~ T.min.to!string() ~ ":" ~ T.max.to!string() ~ "]};"));
    }
    writeln(doParse!T(BINS));

    procDyanamicBins();
    procStaticBins();
  }
  // the number of bins and which one is hit is made out by the
  // sample function
  size_t [] _sbinsNum;
  Bin!(T)[] _bins;
  Bin!(T)[] _sbins;
  Bin!(T)[] _dbins;	     // We keep a count of how many times a bin is hit
  int _pos;	     // position of t the covergoup; -1 otherwise
  void _initPoint(G)(G g) {
    auto _outer = g.outer;
    assert (_outer !is null);
    static if (__traits(hasMember, g, t.stringof)) {
      _point = &(__traits(getMember, g, t.stringof));
      assert(_point !is null);
    }
    else static if (__traits(hasMember, g.outer, t.stringof)) {
      _point = &(__traits(getMember, _outer, t.stringof));
      assert(_point !is null);
    }
    else {
      _point = &(t);
      assert(_point !is null);
    }
    static if (isIntegral!T) {
      _bins.length = 64;
    }
    else static if (is(T == bool)) {
      _bins.length = 2;
    }
    else {
      static if (T.SIZE > 6) {
        _bins.length = 64;
      }
      else {
        _bins.length = T.max - T.min;
      }
    }
  }

  void _initPos(int pos) {
    _pos = pos;
  }

  auto getBins() {
    return _bins;
  }
  void print(){
    import std.stdio;
    /*
       foreach(elem; outBuffer){
       write(elem);
       }*/
    write(outBuffer);
  }
  import std.stdio;

  import std.conv;
  void procDyanamicBins(){
    foreach(tempBin; _dbins){
      auto ranges = tempBin.getRanges();
      size_t num = 0;
      for(size_t i = 0; i < ranges.length; i++){
        for(T j = ranges[i]._min; j <= ranges[i]._max; j++){
          string tempname = tempBin.getName ~ "[" ~ to!string(num) ~ "]";
          _bins ~= Bin!T(tempname);
          _bins[$ - 1].addRange(j);
          ++num;
        }
      }
    }
    _dbins.length = 0;
  }
  void procStaticBins(){
    foreach(index, tempBin; _sbins){
      size_t count = tempBin.count();
      auto ranges = tempBin.getRanges();
      size_t arrSize = _sbinsNum[index];
      T Binsize = to!(T)(count / arrSize) + 1;
      T rem = to!(T)(count % arrSize);
      if(rem == 0)
        Binsize--;
      size_t binNum = 0;
      T binleft = Binsize;
      for(size_t i = 0; i < arrSize; i++){
        _bins ~= Bin!T(tempBin.getName ~ "[" ~ to!string(i) ~ "]");
      }
      if(Binsize == 0){
        assert(false, "array size created more than the number of elements in the array");
      }
      for(size_t i = 0; i < ranges.length; i++){
        if(binleft == 0){
          binNum ++;
          assert(binNum < arrSize);
          if(binNum == rem){
            Binsize --;
          }
          binleft = Binsize;
        }
        /* if(Binsize != 1){ */
        size_t rangeCount = ranges[i]._max - ranges[i]._min + 1;
        if(rangeCount > binleft){
          //makeBins ~= 
          _bins[$ - (arrSize - binNum)].addRange((ranges[i]._min), (ranges[i]._min + binleft - 1));
          ranges[i]._min += binleft;
          binleft = 0;
          --i;
        }
        else{
          //makeBins ~= 
          _bins[$ - (arrSize - binNum)].addRange((ranges[i]._min),  (ranges[i]._max));
          binleft -= rangeCount;
        }
      }
    }
    _sbins.length = 0;
    _sbinsNum.length = 0;
  }

  string describe(){
    string s = "";
    foreach(bin; _bins){
      s ~= bin.describe();
    }
    s ~= "\n";
    return s;
  }
  override void sample(){
    foreach(bin;_bins){
      if(bin.checkHit(t)){
        bin._hits++;
      }
    } 
  }
  override double get_coverage(){
    return 0;
  }
  override double get_inst_coverage(){
    return 0;

  }
  override void start(){

  }
  override void stop(){

  }
  override bool [] get_inst_hits(){
    return _inst_hits;
  }
}

/*class CoverGroup: rand.disable {		// Base Class
  bool _isInitialized;		// true if the CoverGroup has been initialized
  }*/

private void initialize(G, int I=0)(G g) if (is(G: CoverGroup)) {
  static if (I == 0) {
    if (g._isInitialized) return;
    else g._isInitialized = true;
  }
  static if (I >= G.tupleof.length) {
    return;
  }
  else {
    alias E = typeof(g.tupleof[I]);
    static if (is (E: CoverPoint!(t, S), alias t, string S)) {
      g.tupleof[I]._initPoint(g);
      int index = findElementIndex!(t.stringof, G);
      g.tupleof[I]._initPos(index);
    }
    initialize!(G, I+1)(g);
  }
}

private void samplePoints(int I, int N, G)(G g) if (is(G: CoverGroup)) {
  static if (I >= G.tupleof.length) {
    return;
  }
  else {
    alias E = typeof(g.tupleof[I]);
    static if (is (E: CoverPoint!(t, S), alias t, string S)) {
      g.tupleof[I].sample(N);
    }
    samplePoints!(I+1, N)(g);
  }
}


public void sample(G, V...)(G g, V v) if (is(G: CoverGroup)) {
  // navigate through the class elements of G to know the CoverPoint
  // instantiations as well as any Integral/BitVector instances
  sampleArgs!(0)(g, v);
  initialize(g);
  // Now look for all the coverpoints
  samplePoints!(0, V.length)(g);
}

private void sampleArgs(int I, G, V...)(G g, V v) {
  import std.traits: isAssignable;
  static if (V.length == 0) {
    return;
  }
  else {
    alias VAL_TUPLE = getIntElements!G;
    alias N = VAL_TUPLE[I];
    static assert (isAssignable!(typeof(G.tupleof[N]), V[0]),
        "Method sample called with argument of type " ~
        V[0].stringof ~ " at position " ~ I.stringof ~
        " is not assignable to type " ~
        typeof(G.tupleof[N]).stringof);
    static if (I == 0) {
      static assert (VAL_TUPLE.length >= V.length,
          "Method sample called with " ~ V.length.stringof ~
          " arguments, while it can take only " ~
          VAL_TUPLE.length.stringof ~
          " arguments for covergroup of type: " ~ G.stringof);
    }
    g.tupleof[N] = v[0];
    sampleArgs!(I+1)(g, v[1..$]);
  }
}

// return a tuple of integral elements
private template getIntElements(G, int N=0, I...) {
  import std.traits: isIntegral;
  import esdl.data.bvec: isBitVector;
  static if (N == G.tupleof.length) {
    enum getIntElements = I;
  }
  else {
    alias T = typeof(G.tupleof[N]);
    static if (isBitVector!T || isIntegral!T || is(T == bool)) {
      enum getIntElements = getIntElements!(G, N+1, I, N);
    }
    else {
      enum getIntElements = getIntElements!(G, N+1, I);
    }
  }
}

private template findElementIndex(string E, G, int I=0, int N=0) {
  import std.traits: isIntegral;
  import esdl.data.bvec: isBitVector;
  static if(I >= G.tupleof.length) {
    enum findElementIndex = -1;
  } else {
    alias T = typeof(G.tupleof[I]);
    static if (isBitVector!T || isIntegral!T || is(T == bool)) {
      static if (E == G.tupleof[I].stringof) {
        enum findElementIndex = N;
      }
      else {
        enum findElementIndex =  findElementIndex!(E, G, I+1, N+1);
      }
    }
    else {
      enum findElementIndex = findElementIndex!(E, G, I+1, N);
    }
  }
}

private template nthIntElement(alias g, int N, int I=0) {
  import std.traits: isIntegral;
  import esdl.data.bvec: isBitVector;
  static assert(I < g.tupleof.length);
  alias T = typeof(g.tupleof[I]);
  static if (isBitVector!T || isIntegral!T || is(T == bool)) {
    static if (N == 0) {
      enum nthIntElement = g.tupleof[I];
    }
    else {
      enum nthIntElement = nthIntElement!(g, N-1, I+1);
    }
  }
  else {
    enum nthIntElement = nthIntElement!(g, N, I+1);
  }
}

private template countIntElements(G, int COUNT=0, int I=0) {
  import std.traits: isIntegral;
  import esdl.data.bvec: isBitVector;
  static if (I != G.tupleof.length) {
    alias T = typeof(G.tupleof[I]);
    static if (isBitVector!T || isIntegral!T || is(T == bool)) {
      enum countIntElements = countIntElements!(G, COUNT+1, I+1);
    }
    else {
      enum countIntElements = countIntElements!(G, COUNT, I+1);
    }
  }
  else {
    enum countIntElements = COUNT;
  }
}
void main (){
  /* int [] tmp; */
  /* tmp ~= 1;tmp ~= 5; */
  /* writeln(arrayInitialising(2,"hello", tmp)); */
}
unittest {
  int p;
  auto x = new CoverPoint!(p, q{
      bins a = {     1 , 2 }  ;

      })();
  import std.stdio;
  /* writeln(x.describe()); */
  //x.print();
  //import std.stdio;
  //writeln(x.describe());
}
unittest {
  int p;
  auto x = new CoverPoint!(p, q{
      bins a = { [0:63],65 };
      bins [] b = { [127:130],[137:147],200,[100:108] }; // note overlapping values
      bins [3]c = { 200,201,202,204 };
      bins d = { [1000:$] };
      bins e = { 125 };
      //bins [] others = { 1927, 1298 , 2137, [12: 1000]};
      })();
  import std.stdio;
  /* writeln(x.describe()); */
  //import std.stdio;
  //writeln(x.describe());
}
unittest {
  int p;
  auto x = new CoverPoint!(p, q{
      bins [32] a = {[-2147483647:2147483647]};
      })();
  import std.stdio;
  /* writeln(x.describe()); */
}
unittest{
  int a = 5, d = 2;
  auto cp = new CoverPoint!(d,q{
      bins [2] a = {2,3};
      })();
  auto cp2 = new CoverPoint!(a,q{
    bins [] cp2 = {4,5};
  })();
  auto x = new Cross!(cp,cp2)();
  /* writeln(cp.describe()); */
  /* writeln(cp2.describe()); */
  cp.sample();
  cp2.sample();
  x.sample();
  writeln(x.len,x._hits.length);
  foreach(i, elem; x._hits){
    foreach(j,elem2; elem){
      writeln(i,j,elem2);
    }
  }
}
