//
//  Physics.h
//  CatNap
//
//  Created by Ryoichi Hara on 2014/06/07.
//  Copyright (c) 2014年 Ryoichi Hara. All rights reserved.
//

typedef NS_OPTIONS(NSUInteger, CNPhysicsCategory) {
    CNPhysicsCategoryCat    = 1 << 0,  // 0000001 = 1
    CNPhysicsCategoryBlock  = 1 << 1,  // 0000010 = 2
    CNPhysicsCategoryBed    = 1 << 2,  // 0000100 = 4
    CNPhysicsCategoryEdge   = 1 << 3,  // 0001000 = 8
    CNPhysicsCategoryLabel  = 1 << 4,  // 0010000 = 16
    CNPhysicsCategorySpring = 1 << 5,  // 0100000 = 32
    CNPhysicsCategoryHook   = 1 << 6,  // 1000000 = 64
};
