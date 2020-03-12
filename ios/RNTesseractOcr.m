
#import "RNTesseractOcr.h"
#import "RCTLog.h"
#import "GPUImage.h"

@implementation RNTesseractOcr  {
    G8Tesseract *_tesseract;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (NSDictionary *)constantsToExport
{
    return @{
             @"LANG_AFRIKAANS": @"afr",
             @"LANG_AMHARIC": @"amh",
             @"LANG_ARABIC": @"ara",
             @"LANG_ASSAMESE": @"asm",
             @"LANG_AZERBAIJANI": @"aze",
             @"LANG_BELARUSIAN": @"bel",
             @"LANG_BOSNIAN": @"bos",
             @"LANG_BULGARIAN": @"bul",
             @"LANG_CHINESE_SIMPLIFIED": @"chi_sim",
             @"LANG_CHINESE_TRADITIONAL": @"chi_tra",
             @"LANG_CROATIAN": @"hrv",
             @"LANG_CUSTOM": @"custom",
             @"LANG_DANISH": @"dan",
             @"LANG_ENGLISH": @"eng",
             @"LANG_ESTONIAN": @"est",
             @"LANG_FRENCH": @"fra",
             @"LANG_GALICIAN": @"glg",
             @"LANG_GERMAN": @"deu",
             @"LANG_HEBREW": @"heb",
             @"LANG_HUNGARIAN": @"hun",
             @"LANG_ICELANDIC": @"isl",
             @"LANG_INDONESIAN": @"ind",
             @"LANG_IRISH": @"gle",
             @"LANG_ITALIAN": @"ita",
             @"LANG_JAPANESE": @"jpn",
             @"LANG_KOREAN": @"kor",
             @"LANG_LATIN": @"lat",
             @"LANG_LITHUANIAN": @"lit",
             @"LANG_NEPALI": @"nep",
             @"LANG_NORWEGIAN": @"nor",
             @"LANG_PERSIAN": @"fas",
             @"LANG_POLISH": @"pol",
             @"LANG_PORTUGUESE": @"por",
             @"LANG_RUSSIAN": @"rus",
             @"LANG_SERBIAN": @"srp",
             @"LANG_SLOVAK": @"slk",
             @"LANG_SPANISH": @"spa",
             @"LANG_SWEDISH": @"swe",
             @"LANG_TURKISH": @"tur",
             @"LANG_UKRAINIAN": @"ukr",
             @"LANG_VIETNAMESE": @"vie"
             };
}

RCT_EXPORT_MODULE()
RCT_EXPORT_METHOD(recognize:(nonnull NSString*)path
                  language:(nonnull NSString*)language
                  options:(nullable NSDictionary*)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    RCTLogInfo(@"starting Ocr");
    
    _tesseract = [[G8Tesseract alloc] initWithLanguage:language];
//    _tesseract.image = [[UIImage imageWithData:[NSData dataWithContentsOfFile:path]] g8_blackAndWhite];
    
    UIImage *originImg = [UIImage imageNamed:path];
    _tesseract.image = [self processImage:originImg];
    
    _tesseract.engineMode = G8OCREngineModeTesseractOnly;
    _tesseract.pageSegmentationMode = G8PageSegmentationModeAuto;
    //_tesseract.delegate = self;
    
    if(options != NULL) {
        NSString *whitelist = [options valueForKey:@"whitelist"];
        if(![whitelist isEqual: [NSNull null]] && [whitelist length] > 0){
            _tesseract.charWhitelist = whitelist;
        }
        
        NSString *blacklist = [options valueForKey:@"blacklist"];
        if(![blacklist isEqual: [NSNull null]] && [blacklist length] > 0){
            _tesseract.charBlacklist = blacklist;
        }
        
//        NSString *characterChoices = [options valueForKey:@"characterChoices"];
//        if([blacklist length] > 0){
//            _tesseract.characterChoices = blacklist;
//        }
    }
    
    BOOL success = _tesseract.recognize;
    NSString *recognizedText = _tesseract.recognizedText;
    
    NSArray *characterBoxes = [_tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelSymbol];
    NSMutableArray *boxes = [[NSMutableArray alloc] initWithCapacity:characterBoxes.count];
    
    for (G8RecognizedBlock *block in characterBoxes) {
        [boxes addObject:@{
                           @"text" : block.text,
                           @"boundingBox" : @{
                                   @"x": [NSNumber numberWithFloat:block.boundingBox.origin.x],
                                   @"y": [NSNumber numberWithFloat:block.boundingBox.origin.y],
                                   @"width": [NSNumber numberWithFloat:block.boundingBox.size.width],
                                   @"height": [NSNumber numberWithFloat:block.boundingBox.size.height]
                                   },
                           @"confidence" : [NSNumber numberWithFloat:block.confidence],
                           @"level" : [NSNumber numberWithInt:block.level]
                           }];
    }
    
    resolve([NSString stringWithFormat:@"%@", recognizedText]);
    
    // reject(@"no_events", @"There were no events", error);
}

- (UIImage*) processImage:(UIImage*)image  {
    // Create image rectangle with current image width/height
//    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
//
//    // Grayscale color space
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
//
//    // Create bitmap content with current image size and grayscale colorspace
//    CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
//
//    // Draw image into current context, with specified rectangle
//    // using previously defined context (with grayscale colorspace)
//    CGContextDrawImage(context, imageRect, [image CGImage]);
//
//    // Create bitmap image info from pixel data in current context
//    CGImageRef imageRef = CGBitmapContextCreateImage(context);
//
//    // Create a new UIImage object
//    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
//
//    // Release colorspace, context and bitmap information
//    CGColorSpaceRelease(colorSpace);
//    CGContextRelease(context);
//    CFRelease(imageRef);
    
    // Initialize our adaptive threshold filter
    GPUImageAdaptiveThresholdFilter *stillImageFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
    stillImageFilter.blurRadiusInPixels = 12.0; // adjust this to tweak the blur radius of the filter, defaults to 4.0

    // Retrieve the filtered image from the filter
    UIImage *newImage = [stillImageFilter imageByFilteringImage:image];
    
    return newImage;
}

@end

