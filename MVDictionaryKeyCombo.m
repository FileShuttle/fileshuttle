//
//  SRDictionaryKeyCombo.m
//  FileShuttle
//
//  Created by Michael Villar on 12/26/11.
//

#import "MVDictionaryKeyCombo.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
NSDictionary* MVDictionaryFromKeyCombo(KeyCombo keyCombo) 
{
	NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithShort:keyCombo.code], @"keyCode",
                          [NSNumber numberWithUnsignedInteger:keyCombo.flags], @"modifierFlags",
							nil];
	return values;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
KeyCombo MVKeyComboFromDictionary(NSDictionary *dic)
{
	short keyCode = [[dic valueForKey:@"keyCode"] shortValue];
	unsigned int modifiedFlags = [[dic valueForKey:@"modifierFlags"] unsignedIntValue];
	return SRMakeKeyCombo(keyCode, modifiedFlags);
}