/****************************************************************************
 Copyright (c) 2013 cocos2d-x.org
 
 http://www.cocos2d-x.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#import "CCUserDefault.h"
#import <string>
#import "platform/CCFileUtils.h"
#import "tinyxml2.h"
#import "CCPlatformConfig.h"
#import "CCPlatformMacros.h"
#import "base64.h"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS) || (CC_TARGET_PLATFORM == CC_PLATFORM_MAC)


#define XML_FILE_NAME "UserDefault.xml"

// root name of xml
#define USERDEFAULT_ROOT_NAME    "userDefaultRoot"

#define KEEP_COMPATABILITY

using namespace std;

NS_CC_BEGIN

/**
 * implements of UserDefault
 */

UserDefault* UserDefault::_userDefault = 0;
string UserDefault::_filePath = string("");
bool UserDefault::_isFilePathInitialized = false;

#ifdef KEEP_COMPATABILITY
static tinyxml2::XMLElement* getXMLNodeForKey(const char* pKey, tinyxml2::XMLDocument **doc)
{
    tinyxml2::XMLElement* curNode = nullptr;
    tinyxml2::XMLElement* rootNode = nullptr;
    
    if (! UserDefault::isXMLFileExist())
    {
        return nullptr;
    }
    
    // check the key value
    if (! pKey)
    {
        return nullptr;
    }
    
    do
    {
 		tinyxml2::XMLDocument* xmlDoc = new tinyxml2::XMLDocument();
		*doc = xmlDoc;
		ssize_t size;
		char* pXmlBuffer = (char*)FileUtils::getInstance()->getFileData(UserDefault::getInstance()->getXMLFilePath().c_str(), "rb", &size);
		//const char* pXmlBuffer = (const char*)data.getBuffer();
		if(nullptr == pXmlBuffer)
		{
            NSLog(@"can not read xml file");
			break;
		}
		xmlDoc->Parse(pXmlBuffer);
        free(pXmlBuffer);
		// get root node
		rootNode = xmlDoc->RootElement();
		if (nullptr == rootNode)
		{
            NSLog(@"read root node error");
			break;
		}
		// find the node
		curNode = rootNode->FirstChildElement();
        if (!curNode)
        {
            // There is not xml node, delete xml file.
            remove(UserDefault::getInstance()->getXMLFilePath().c_str());
            
            return nullptr;
        }
        
		while (nullptr != curNode)
		{
			const char* nodeName = curNode->Value();
			if (!strcmp(nodeName, pKey))
			{
                // delete the node
				break;
			}
            
			curNode = curNode->NextSiblingElement();
		}
	} while (0);
    
	return curNode;
}

static void deleteNode(tinyxml2::XMLDocument* doc, tinyxml2::XMLElement* node)
{
    if (node)
    {
        doc->DeleteNode(node);
        doc->SaveFile(UserDefault::getInstance()->getXMLFilePath().c_str());
        delete doc;
    }
}

static void deleteNodeByKey(const char *pKey)
{
    tinyxml2::XMLDocument* doc = nullptr;
    tinyxml2::XMLElement* node = getXMLNodeForKey(pKey, &doc);
    deleteNode(doc, node);
}
#endif

/**
 * If the user invoke delete UserDefault::getInstance(), should set _userDefault
 * to null to avoid error when he invoke UserDefault::getInstance() later.
 */
UserDefault::~UserDefault()
{
	CC_SAFE_DELETE(_userDefault);
    _userDefault = nullptr;
}

UserDefault::UserDefault()
{
	_userDefault = nullptr;
}

bool UserDefault::getBoolForKey(const char* pKey)
{
    return getBoolForKey(pKey, false);
}

bool UserDefault::getBoolForKey(const char* pKey, bool defaultValue)
{
#ifdef KEEP_COMPATABILITY
    tinyxml2::XMLDocument* doc = nullptr;
    tinyxml2::XMLElement* node = getXMLNodeForKey(pKey, &doc);
    if (node)
    {
        if (node->FirstChild())
        {
            const char* value = (const char*)node->FirstChild()->Value();
            bool ret = (! strcmp(value, "true"));
            
            // set value in NSUserDefaults
            setBoolForKey(pKey, ret);
            flush();
            
            // delete xmle node
            deleteNode(doc, node);
            
            return ret;
        }
        else
        {
            // delete xmle node
            deleteNode(doc, node);
        }
    }
#endif
    
    bool ret = defaultValue;
    
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithUTF8String:pKey]];
    if (value)
    {
        ret = [value boolValue];
    }
    
    return ret;
}

int UserDefault::getIntegerForKey(const char* pKey)
{
    return getIntegerForKey(pKey, 0);
}

int UserDefault::getIntegerForKey(const char* pKey, int defaultValue)
{
#ifdef KEEP_COMPATABILITY
    tinyxml2::XMLDocument* doc = nullptr;
    tinyxml2::XMLElement* node = getXMLNodeForKey(pKey, &doc);
    if (node)
    {
        if (node->FirstChild())
        {
            int ret = atoi((const char*)node->FirstChild()->Value());
            
            // set value in NSUserDefaults
            setIntegerForKey(pKey, ret);
            flush();
            
            // delete xmle node
            deleteNode(doc, node);
            
            return ret;
        }
        else
        {
            // delete xmle node
            deleteNode(doc, node);
        }
    }
#endif
    
    int ret = defaultValue;
    
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithUTF8String:pKey]];
    if (value)
    {
        ret = [value intValue];
    }
    
    return ret;
}

float UserDefault::getFloatForKey(const char* pKey)
{
    return getFloatForKey(pKey, 0);
}

float UserDefault::getFloatForKey(const char* pKey, float defaultValue)
{
#ifdef KEEP_COMPATABILITY
    tinyxml2::XMLDocument* doc = nullptr;
    tinyxml2::XMLElement* node = getXMLNodeForKey(pKey, &doc);
    if (node)
    {
        if (node->FirstChild())
        {
            float ret = atof((const char*)node->FirstChild()->Value());
            
            // set value in NSUserDefaults
            setFloatForKey(pKey, ret);
            flush();
            
            // delete xmle node
            deleteNode(doc, node);
            
            return ret;
        }
        else
        {
            // delete xmle node
            deleteNode(doc, node);
        }
    }
#endif
    
    float ret = defaultValue;
    
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithUTF8String:pKey]];
    if (value)
    {
        ret = [value floatValue];
    }
    
    return ret;
}

double  UserDefault::getDoubleForKey(const char* pKey)
{
    return getDoubleForKey(pKey, 0);
}

double UserDefault::getDoubleForKey(const char* pKey, double defaultValue)
{
#ifdef KEEP_COMPATABILITY
    tinyxml2::XMLDocument* doc = nullptr;
    tinyxml2::XMLElement* node = getXMLNodeForKey(pKey, &doc);
    if (node)
    {
        if (node->FirstChild())
        {
            double ret = atof((const char*)node->FirstChild()->Value());
            
            // set value in NSUserDefaults
            setDoubleForKey(pKey, ret);
            flush();
            
            // delete xmle node
            deleteNode(doc, node);
            
            return ret;
        }
        else
        {
            // delete xmle node
            deleteNode(doc, node);
        }
    }
#endif
    
	double ret = defaultValue;
    
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithUTF8String:pKey]];
    if (value)
    {
        ret = [value doubleValue];
    }
    
    return ret;
}

std::string UserDefault::getStringForKey(const char* pKey)
{
    return getStringForKey(pKey, "");
}

string UserDefault::getStringForKey(const char* pKey, const std::string & defaultValue)
{
#ifdef KEEP_COMPATABILITY
    tinyxml2::XMLDocument* doc = nullptr;
    tinyxml2::XMLElement* node = getXMLNodeForKey(pKey, &doc);
    if (node)
    {
        if (node->FirstChild())
        {
            string ret = (const char*)node->FirstChild()->Value();
            
            // set value in NSUserDefaults
            setStringForKey(pKey, ret);
            flush();
            
            // delete xmle node
            deleteNode(doc, node);
            
            return ret;
        }
        else
        {
            // delete xmle node
            deleteNode(doc, node);
        }
    }
#endif
    
    NSString *str = [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithUTF8String:pKey]];
    if (! str)
    {
        return defaultValue;
    }
    else
    {
        return [str UTF8String];
    }
}

Data* UserDefault::getDataForKey(const char* pKey)
{
    return getDataForKey(pKey, nullptr);
}

Data* UserDefault::getDataForKey(const char* pKey, Data* defaultValue)
{
#ifdef KEEP_COMPATABILITY
    tinyxml2::XMLDocument* doc = nullptr;
    tinyxml2::XMLElement* node = getXMLNodeForKey(pKey, &doc);
    if (node)
    {
        if (node->FirstChild())
        {
            const char * encodedData = node->FirstChild()->Value();
            unsigned char * decodedData;
            int decodedDataLen = base64Decode((unsigned char*)encodedData, (unsigned int)strlen(encodedData), &decodedData);

            if (decodedData) {
                Data *ret = Data::create(decodedData, decodedDataLen);
                
                // set value in NSUserDefaults
                setDataForKey(pKey, ret);
                
                free(decodedData);
                
                flush();
                
                // delete xmle node
                deleteNode(doc, node);
                
                return ret;
            }
        }
        else
        {
            // delete xmle node
            deleteNode(doc, node);
        }
    }
#endif
    
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:[NSString stringWithUTF8String:pKey]];
    if (! data)
    {
        return defaultValue;
    }
    else
    {
        unsigned char *bytes = {0};
        int size = 0;
        
        if (data.length > 0) {
            bytes = (unsigned char*)data.bytes;
            size = static_cast<int>(data.length);
        }
        Data *ret = new Data(bytes, size);
        
        ret->autorelease();
        
        return ret;
    }
}

void UserDefault::setBoolForKey(const char* pKey, bool value)
{
#ifdef KEEP_COMPATABILITY
    deleteNodeByKey(pKey);
#endif
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:value] forKey:[NSString stringWithUTF8String:pKey]];
}

void UserDefault::setIntegerForKey(const char* pKey, int value)
{
#ifdef KEEP_COMPATABILITY
    deleteNodeByKey(pKey);
#endif
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:value] forKey:[NSString stringWithUTF8String:pKey]];
}

void UserDefault::setFloatForKey(const char* pKey, float value)
{
#ifdef KEEP_COMPATABILITY
    deleteNodeByKey(pKey);
#endif
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:value] forKey:[NSString stringWithUTF8String:pKey]];
}

void UserDefault::setDoubleForKey(const char* pKey, double value)
{
#ifdef KEEP_COMPATABILITY
    deleteNodeByKey(pKey);
#endif
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:value] forKey:[NSString stringWithUTF8String:pKey]];
}

void UserDefault::setStringForKey(const char* pKey, const std::string & value)
{
#ifdef KEEP_COMPATABILITY
    deleteNodeByKey(pKey);
#endif
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithUTF8String:value.c_str()] forKey:[NSString stringWithUTF8String:pKey]];
}

void UserDefault::setDataForKey(const char* pKey, const Data& value) {
#ifdef KEEP_COMPATABILITY
    deleteNodeByKey(pKey);
#endif
        
    [[NSUserDefaults standardUserDefaults] setObject:[NSData dataWithBytes: value.getBytes() length: value.getSize()] forKey:[NSString stringWithUTF8String:pKey]];
}

UserDefault* UserDefault::getInstance()
{
#ifdef KEEP_COMPATABILITY
    initXMLFilePath();
#endif
    
    if (! _userDefault)
    {
        _userDefault = new UserDefault();
    }
    
    return _userDefault;
}

void UserDefault::destroyInstance()
{
    delete _userDefault;
    _userDefault = nullptr;
}

// XXX: deprecated
UserDefault* UserDefault::sharedUserDefault()
{
    return UserDefault::getInstance();
}

// XXX: deprecated
void UserDefault::purgeSharedUserDefault()
{
    UserDefault::destroyInstance();
}

bool UserDefault::isXMLFileExist()
{
    FILE *fp = fopen(_filePath.c_str(), "r");
	bool bRet = false;
    
	if (fp)
	{
		bRet = true;
		fclose(fp);
	}
    
	return bRet;
}

void UserDefault::initXMLFilePath()
{
#ifdef KEEP_COMPATABILITY
    if (! _isFilePathInitialized)
    {
        // xml file is stored in cache directory before 2.1.2
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _filePath = [documentsDirectory UTF8String];
        _filePath.append("/");
        
        _filePath +=  XML_FILE_NAME;
        _isFilePathInitialized = true;
    }
#endif
}

// create new xml file
bool UserDefault::createXMLFile()
{
    return false;
}

const string& UserDefault::getXMLFilePath()
{
    return _filePath;
}

void UserDefault::flush()
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}


NS_CC_END

#endif // (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)