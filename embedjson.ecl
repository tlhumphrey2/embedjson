 

STRING modifyJSON(STRING json) := BEGINC++

#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"
#include <iostream>
using namespace rapidjson;
using ::StringBuffer;  //Resolve conflict between HPCC StringBuffer and rapidjson::StringBuffer

  #body

    Document d;
    d.Parse<kParseDefaultFlags>((const rapidjson::UTF8<>::Ch *)json);

    Value& s = d["stars"];
    s.SetInt(s.GetInt() + 1);

    rapidjson::StringBuffer buffer;
    Writer<rapidjson::StringBuffer> writer(buffer);
    d.Accept(writer);

    const char *str = buffer.GetString();


    size32_t len = strlen(str);
    char * out = (char *)rtlMalloc(len);
    for (unsigned i= 0; i < len; i++)
        out[i] = str[i];
 __lenResult = len;
 __result = out;
ENDC++;

OUTPUT(modifyJSON('{"project": "rapidjson", "stars": 10}'));

projectsRecord := RECORD
    STRING name;
    unsigned1 stars;
END;

dataset(projectsRecord) jsonDataset(string json) := BEGINC++

    Document d;
    d.Parse<kParseDefaultFlags>((const rapidjson::UTF8<>::Ch *)json);

    Value &rows = d["row"];
    unsigned cnt = (unsigned) rows.Size();
    unsigned len=0;
    for (unsigned i = 0; i < cnt; i++)
    {
        Value& row = rows[SizeType(i)];
        len += sizeof(size32_t) + strlen((const char *)row["project"].GetString()) + sizeof(unsigned char);
    }

    byte * p = (byte *)rtlMalloc(len);
    unsigned offset = 0;
    for (unsigned j = 0; j < cnt; j++)
    {
        Value& row = rows[SizeType(j)];
        const char *cstr = (const char *) row["project"].GetString();
        *(size32_t *)(p + offset) = strlen(cstr);
        offset += sizeof(size32_t);
        memcpy(p+offset, cstr, strlen(cstr));
        offset += strlen(cstr);
        *(unsigned char*)(p + offset)= (unsigned char) row["stars"].GetUint();
        offset += sizeof(unsigned char);
    }

    __lenResult = len;
    __result = p;
ENDC++;

OUTPUT(jsonDataset('{"row": [{"project": "rapidjson", "stars": 10}, {"project": "rapidxml", "stars": 9}]}'));

