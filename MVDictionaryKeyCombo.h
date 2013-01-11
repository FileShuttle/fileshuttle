//
//  SRDictionaryKeyCombo.h
//  FileShuttle
//
//  Created by Michael Villar on 12/26/11.
//

#import <Foundation/Foundation.h>
#import <ShortcutRecorder/ShortcutRecorder.h>

NSDictionary* MVDictionaryFromKeyCombo(KeyCombo keyCombo);
KeyCombo MVKeyComboFromDictionary(NSDictionary *dic);