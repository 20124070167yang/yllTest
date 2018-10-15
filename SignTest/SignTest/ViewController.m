//
//  ViewController.m
//  SignTest
//
//  Created by juli on 2018/1/15.
//  Copyright © 2018年 juli. All rights reserved.
//

#import "ViewController.h"
#import <CommonCrypto/CommonDigest.h>
//#import "EncodingUtil.h"
#import <Photos/Photos.h>
#import <Messages/Messages.h>
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import "AFNetworking.h"
#define CLog(format, ...)  NSLog(format, ## __VA_ARGS__)

#define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String])

#define RGBColor(r,g,b) [UIColor colorWithRed:(r)/ 255.0f green:(g)/255.0f blue:(b)/ 255.0f alpha:1]
@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

//图片
@property(nonatomic,strong)UIImageView *imgView;

//检测结果
@property(nonatomic,strong)UITextView *textView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSObject *obj = [[NSObject alloc]init];
  size_t size =  class_getInstanceSize([obj class]);
    NSLog(@"size is %ld",size);
 size_t size2 =   malloc_size((__bridge const void *)obj);
    NSLog(@"size2 is %ld",size2);
    
  CGFloat height =  [[UIApplication sharedApplication]statusBarFrame].size.height;
    NSLog(@"heightis %f",height);
  CGFloat scale=  [UIScreen mainScreen].scale;
    NSLog(@"scale is %f",scale);
    
    //设置背景颜色
    self.view.backgroundColor = RGBColor(266, 168, 24);
    //人脸检测按钮
    UIButton *faceBtn = [self createButtonWithRect:CGRectMake(100, 100, 100, 50) withTitle:@"选择照片"];
    [faceBtn addTarget:self action:@selector(faceAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:faceBtn];
    
    //图片
    self.imgView = [UIImageView new];
    self.imgView.frame = CGRectMake(100, 160, 100, 100);
    [self.view addSubview:_imgView];
    
    //开始检测
    UIButton *checkBtn = [self createButtonWithRect:CGRectMake(100, 280, 100, 50) withTitle:@"开始检测"];
    [checkBtn addTarget:self action:@selector(checkAction:) forControlEvents:UIControlEventTouchUpInside];
    
    //设置边框颜色
    checkBtn.layer.borderColor = RGBColor(100, 200, 60).CGColor;
    //设置边框宽度
    checkBtn.layer.borderWidth = 1;
    
    [self.view addSubview:checkBtn];
    
    //检测结果
    self.textView = [[UITextView alloc]initWithFrame:CGRectMake(10, 340, ([UIScreen mainScreen].bounds.size.width) - 20, 300)];
    [self.view addSubview:_textView];
    
    
}

//计算鉴权值
- (NSString*)jlGetSignData:(NSMutableDictionary*)dic withAppKey:(NSString*)appKey
{
    NSMutableDictionary *mudic = [NSMutableDictionary dictionary];
    
    NSArray *allKeys = [dic allKeys];
    
    //字典升序
    NSArray *sortArr = [allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        //
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    NSLog(@"sortArr is %@",sortArr);
    
    NSMutableArray *valueArr = [NSMutableArray array];
    
    //for循环取出value值
    for (NSString *sortString in sortArr) {
        NSString *valueStr = [dic objectForKey:sortString];
        //将value进行URL编码
        NSString *urlEncode=  (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                    NULL,
                                                                    (__bridge CFStringRef)valueStr,
                                                                    NULL,
                                                                    (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                                    CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
        [valueArr addObject:urlEncode ];
    }
    NSMutableArray *signArr = [NSMutableArray array];
    //形成key=value的形式
    for (int i = 0; i < sortArr.count; i ++) {
        NSString *keyValueStr = [NSString stringWithFormat:@"%@=%@",sortArr[i],valueArr[i]];
        [signArr addObject:keyValueStr];
    }
    
    //以&连接键值对
    NSString *sign = [signArr componentsJoinedByString:@"&"];
    

    //将appkey拼接在字符串末尾
    NSMutableString *muStr = [NSMutableString string];
    [muStr appendString:sign];
    [muStr appendString:[NSString stringWithFormat:@"&app_key=%@",appKey]];
   
   
    //进行MD5运算
  NSString *secStr =  [self md5:muStr];
    //将MD5运算结果转化成大写
    NSString *upperSec = [secStr uppercaseString];
    NSLog(@"MD5加密的结果是%@",upperSec);
    return upperSec;
    
    
}
- (NSString *)md5:(NSString *)str
{
   
    const char *cStr = [str UTF8String];
//     NSLog(@"md5参数是%s",cStr);
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (void)netWorkTest:(NSMutableDictionary *)mudic
{
 UIActivityIndicatorView   *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.frame = CGRectMake(0, 0, 100, 100);
    activityIndicator.center = self.view.center;
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    
    NSLog(@"----测试post请求方式----");
    NSString *testURL = @"https://api.ai.qq.com/fcgi-bin/face/face_detectface";
    testURL = [testURL  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:testURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    //设置请求方法
    request.HTTPMethod = @"POST";
    //设置请求体
    NSArray *keys = [mudic allKeys];
    NSMutableArray *arr = [NSMutableArray array];

    for (int i = 0; i <keys.count; i ++) {
        NSString *key = [keys objectAtIndex:i ];
        NSString *value = [mudic objectForKey:key];
        NSString *com = [[NSString alloc]initWithFormat:@"%@=%@",key,value ];
        [arr addObject:com];
        
    }
    NSString *sign = [arr componentsJoinedByString:@"&"];
    NSData *dataTest = [sign dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody =dataTest;
    NSLog(@"------测试post请求方式结束------");
    NSURLSession *session  = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask =  [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //
        if (error) {
            NSLog(@"error is %@",error);
        }else
        {
            NSLog(@"data is %@",data);
            NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"str is %@",str);
            NSDictionary *dic= [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSLog(@"解析得出的dic is %@",dic);
            NSLog(@"ret is %@,msg is%@",dic[@"ret"],dic[@"msg"]);
            NSNumber *ret = dic[@"ret"];
            if (ret.intValue == 0) {
                NSLog(@"检测成功");
                NSDictionary *result = dic[@"data"];
                NSString *str = [NSString stringWithFormat:@"%@",result];
                dispatch_async(dispatch_get_main_queue(), ^{
                    _textView.text = str;
                    [activityIndicator stopAnimating];
                });
            }else
            {
                NSLog(@"检测失败");
                dispatch_async(dispatch_get_main_queue(), ^{
                    _textView.text = [NSString stringWithFormat:@"检测失败：ret:%@,msg:%@",dic[@"ret"],dic[@"msg"]];
                    [activityIndicator stopAnimating];
                });
            }
        }
    }];
    [dataTask resume];
    
}
#pragma mark -开始检测
- (void)startCheckWithImage:(UIImage*)image
{
    _textView.text = @"";
    if (image == nil) {
        return;
    }
    //获取当前时间戳
    NSDate *currentTime = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval time = [currentTime timeIntervalSince1970];
    NSString *currentStr = [NSString stringWithFormat:@"%.0f",time];
    NSLog(@"当前的时间戳是%@",currentStr);
    
    
    NSMutableDictionary *mudic = [NSMutableDictionary dictionary];
    [mudic setObject:@"1106471787" forKey:@"app_id"];
    [mudic setObject:currentStr forKey:@"time_stamp"];
    [mudic setObject:@"o1w5w2rov3" forKey:@"nonce_str"];
    //获取图片对象
//    UIImage *image1 = [UIImage imageNamed:@"timg.jpeg"];
//    NSData *data = UIImagePNGRepresentation(image);
//        NSLog(@"压缩后的图片是%@",data);
    NSData *data = UIImageJPEGRepresentation(image, 0.5);
    
    //原始图片的base64编码
        NSString *encodedImageStr =  [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
//    NSString *encodedImageStr =  [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    //url编码
    NSString *urlEncode=  (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                NULL,
                                                                                                (__bridge CFStringRef)encodedImageStr,
                                                                                                NULL,
                                                                                                (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                                CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
//    NSLog(@"urlEncode is %@",urlEncode);
    //参数--待识别图像(进行网络请求的参数中，原始图片base64编码后还要经过url编码)
    [mudic setObject:urlEncode forKey:@"image"];
    //参数检测模式
    [mudic setObject:@"1" forKey:@"mode"];
    
    /********************计算鉴权值的参数字典************************************/
    NSMutableDictionary *testDic = [NSMutableDictionary dictionary];
    //APPID
    [testDic setObject:@"1106471787" forKey:@"app_id"];
    //时间戳
    [testDic setObject:currentStr forKey:@"time_stamp"];
    //随机字符串
    [testDic setObject:@"o1w5w2rov3" forKey:@"nonce_str"];
    //原始图片的base64编码
    [testDic setObject:encodedImageStr forKey:@"image"];
    //参数检测模式
    [testDic setObject:@"1" forKey:@"mode"];
    /********************************************************/
    
    //计算鉴权值
    NSString *signStr =   [self jlGetSignData:testDic withAppKey:@"tWCXFJfrSVEmu0IB"];
    
    //将计算出的鉴权值加入进行网络 请求的参数字典中
    [mudic setObject:signStr forKey:@"sign"];
    
    //开始进行网络请求
    [self netWorkTest:mudic];
}
#pragma mark -拍照或者是从相册中选择
- (void)faceAction:(UIButton*)btn
{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *albumAction = [UIAlertAction actionWithTitle:@"从手机相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"从手机相册选择");
        
        [self selectPhoto];
    }];
    
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takePhoto];
    }];
    
    //取消
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //
        NSLog(@"取消");
    }];
    [alertVC addAction:albumAction];
    [alertVC addAction:photoAction];
    [alertVC addAction:cancelAction];
    [self presentViewController:alertVC animated:YES completion:^{
        //
    }];
}
#pragma mark -从相册中选择
- (void)selectPhoto
{
    //从相册选择照片
    NSInteger sourceType = 0;
    UIImagePickerController *imageControllerVC = [[UIImagePickerController alloc]init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        //
        imageControllerVC.delegate = self;
        imageControllerVC.allowsEditing = YES;
        sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imageControllerVC.sourceType = sourceType;
        [self presentViewController:imageControllerVC animated:YES completion:nil];
    }
}

#pragma mark -拍照功能
//拍照功能
- (void)takePhoto
{
//    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    [device lockForConfiguration:nil];
//
//
//
//    [device setTorchMode:AVCaptureTorchModeOff];
//
//
//
//    [device unlockForConfiguration];
    //拍照之前检查相机权限
    AVAuthorizationStatus authoStatus =   [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authoStatus == AVAuthorizationStatusNotDetermined) {
        NSLog(@"相机状态未决定");
        NSLog(@"权限状态未决定");
        
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self takePhoto];
                    });
                }
            }];


    }else if(authoStatus == AVAuthorizationStatusDenied || authoStatus == AVAuthorizationStatusRestricted)
    {
        NSLog(@"相机权限被拒或者相机权限受限");

    }else
    {
        NSLog(@"相机状态是正常的");
        NSInteger sourceType = 0;
        UIImagePickerController *imageControllerVC = [[UIImagePickerController alloc]init];
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            //
            imageControllerVC.delegate = self;
            imageControllerVC.allowsEditing = YES;
            imageControllerVC.sourceType = sourceType;
            sourceType = UIImagePickerControllerSourceTypeCamera;
            imageControllerVC.sourceType = sourceType;
            [self presentViewController:imageControllerVC animated:YES completion:nil];
        }
    }
    
}

#pragma mark -用户选择照片完毕
//用户选择照片完毕
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    [picker dismissViewControllerAnimated:YES completion:^{}];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSString *assetString = [[info objectForKey:UIImagePickerControllerReferenceURL] absoluteString];
//    NSLog(@"assetString is %@",assetString);
    NSLog(@"image is %@",image);
    _imgView.image = image;
    
}
#pragma mark -开始检测
- (void)checkAction:(UIButton*)btn
{
   [self startCheckWithImage:_imgView.image];
}
#pragma mark -用户取消选择
//用户取消选择
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    dispatch_async(dispatch_get_main_queue(), ^{
        [picker dismissViewControllerAnimated:YES completion:^{}];
    });
    
}
//个性化button
- (UIButton*)createButtonWithRect:(CGRect)rect withTitle:(NSString*)title
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = rect;
    btn.backgroundColor = [UIColor clearColor];
    [btn setTitle:title forState:UIControlStateNormal];
    return btn;
}


@end
