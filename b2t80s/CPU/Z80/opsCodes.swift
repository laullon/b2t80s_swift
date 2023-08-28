//
//  opsCodes.swift
//  b2t80s
//
//  Created by German Laullon on 18/8/23.
//

import Foundation

var z80OpsCodeTable :[opCode] = [
    opCode("LD dd, mm", 0b11001111, 0b00000001, 3, [mrNNpc(f: ldDDmm)], {cpu in ()}),
    opCode("ADD HL,ss", 0b11001111, 0b00001001, 1, [Exec(l: 7, f: addHLss)], {cpu in ()}),
    opCode("INC ss", 0b11001111, 0b00000011, 1, [Exec(l: 2, f: incSS)], {cpu in ()}),
    opCode("DEC ss", 0b11001111, 0b00001011, 1, [Exec(l: 2, f: decSS)], {cpu in ()}),
    opCode("POP ss", 0b11001111, 0b11000001, 1, [], popSS),
    opCode("PUSH ss", 0b11001111, 0b11000101, 1, [Exec(l: 1, f: pushSS)], {cpu in ()}),

    opCode("LD r, n", 0b11000111, 0b00000110, 2, [mrNpc(f: ldRn)], {cpu in ()},dis_ldrn),
    opCode("LD r, r'", 0b11000000, 0b01000000, 1, [], ldRr),
    opCode("LD r, (HL)", 0b11000111, 0b01000110, 1, [], ldRhl),
    opCode("LD (HL), r", 0b11111000, 0b01110000, 1, [], ldHLr),
    opCode("INC r", 0b11000111, 0b0000100, 1, [], incR),
    opCode("DEC r", 0b11000111, 0b0000101, 1, [], decR),
    opCode("ADD A, r", 0b11111000, 0b10000000, 1, [], addAr),
    opCode("ADC A, r", 0b11111000, 0b10001000, 1, [], adcAr),
    opCode("SUB A, r", 0b11111000, 0b10010000, 1, [], subAr),
    opCode("SBC A, r", 0b11111000, 0b10011000, 1, [], sbcAr),
    opCode("AND r", 0b11111000, 0b10100000, 1, [], andAr),
    opCode("OR r", 0b11111000, 0b10110000, 1, [], orAr),
    opCode("XOR r", 0b11111000, 0b10101000, 1, [], xorAr),
    opCode("CP r", 0b11111000, 0b10111000, 1, [], cpR),

    opCode("RET cc", 0b11000111, 0b11000000, 1, [Exec(l: 1, f: retCC)], {cpu in ()}),
    opCode("JP cc, nn", 0b11000111, 0b11000010, 3, [mrNNpc(f: jpCC)], {cpu in ()}),
    opCode("CALL cc, nn", 0b11000111, 0b11000100, 3, [mrNNpc(f: callCC)], {cpu in ()}),
    opCode("RST p", 0b11000111, 0b11000111, 1, [Exec(l: 1, f: rstP)], {cpu in ()}),
    opCode("CALL nn", 0xFF, 0xCD, 3, [mrNNpc(f: {cpu in ()}), Exec(l: 1, f: call)], {cpu in ()}),

    // {"", 0xFF, 0x1,,[]],nil},
    opCode("NOP", 0xFF, 0x00, 1, [], {cpu in ()}),
    opCode("DAA", 0xFF, 0x27, 1, [], daa),
    opCode("CPL", 0xFF, 0x2f, 1, [], cpl),
    opCode("SCF", 0xFF, 0x37, 1, [], scf),
    opCode("CCF", 0xFF, 0x3F, 1, [], ccf),
    opCode("HALT", 0xFF, 0x76, 1, [], halt),
    opCode("RET", 0xFF, 0xC9, 1, [], ret),

    opCode("INC (HL)", 0xFF, 0x34, 1, [Exec(l: 1, f: incHL)], {cpu in ()}),
    opCode("DEC (HL)", 0xFF, 0x35, 1, [Exec(l: 1, f: decHL)], {cpu in ()}),
    opCode("ADD A, (HL)", 0xFF, 0x86, 1, [], addAhl),
    opCode("ADC A, (HL)", 0xFF, 0x8e, 1, [], adcAhl),
    opCode("SUB A, (HL)", 0xFF, 0x96, 1, [], subAhl),
    opCode("SBC A, (HL)", 0xFF, 0x9e, 1, [], sbcAhl),
    opCode("AND (HL)", 0xFF, 0xA6, 1, [], andAhl),
    opCode("OR (HL)", 0xFF, 0xB6, 1, [], orAhl),
    opCode("XOR (HL)", 0xFF, 0xAE, 1, [], xorAhl),
    opCode("CP (HL)", 0xFF, 0xBE, 1, [], cpHl),
    opCode("ADD A, n", 0xFF, 0xc6, 2, [mrNpc(f: {cpu in cpu.addA(cpu.fetched.n)})], {cpu in ()}),
    opCode("ADC A, (HL)", 0xFF, 0xCE, 2, [mrNpc(f: {cpu in cpu.adcA(cpu.fetched.n)})], {cpu in ()}),
    opCode("SBC A, (HL)", 0xFF, 0xDE, 2, [mrNpc(f: {cpu in cpu.sbcA(cpu.fetched.n)})], {cpu in ()}),
    opCode("SUB n", 0xFF, 0xD6, 2, [mrNpc(f: {cpu in cpu.subA(cpu.fetched.n)})], {cpu in ()}),
    opCode("AND n", 0xFF, 0xE6, 2, [mrNpc(f: {cpu in cpu.and(cpu.fetched.n)})], {cpu in ()}),
    opCode("OR n", 0xFF, 0xF6, 2, [mrNpc(f: {cpu in cpu.or(cpu.fetched.n)})], {cpu in ()}),

    opCode("LD A,(BC)", 0xFF, 0x0A, 1, [], ldAbc),
    opCode("LD A,(DE)", 0xFF, 0x1A, 1, [], ldAde),
    opCode("LD (BC), A", 0xFF, 0x02, 1, [], ldBCa),
    opCode("LD (BC), A", 0xFF, 0x12, 1, [], ldDEa),
    opCode("LD (nn), HL", 0xFF, 0x22, 3, [mrNNpc(f: ldNNhl)], {cpu in ()}),
    opCode("LD (nn), A", 0xFF, 0x32, 3, [mrNNpc(f: ldNNa)], {cpu in ()}),
    opCode("LD HL, (nn)", 0xFF, 0x2a, 3, [mrNNpc(f: ldHLnn)], {cpu in ()}),
    opCode("LD (HL), n", 0xFF, 0x36, 2, [mrNpc(f: ldHLn)], {cpu in ()}),
    opCode("LD A, (nn)", 0xFF, 0x3a, 3, [mrNNpc(f: ldAnn)], {cpu in ()}),

    opCode("EX AF, AF'", 0xFF, 0x08, 1, [], exafaf),
    opCode("EXX'", 0xFF, 0xD9, 1, [], exx),

    opCode("DJNZ e", 0xFF, 0x10, 2, [mrNpc(f: {cpu in ()}), Exec(l: 1, f: djnz)], {cpu in ()}),
    opCode("JR e", 0xFF, 0x18, 2, [mrNpc(f: {cpu in ()}), Exec(l: 5, f: jr)], {cpu in ()}),
    opCode("JRNZ e", 0xFF, 0x20, 2, [mrNpc(f: jrnz)], {cpu in ()}),
    opCode("JRZ e", 0xFF, 0x28, 2, [mrNpc(f: jrz)], {cpu in ()}),
    opCode("JRNC e", 0xFF, 0x30, 2, [mrNpc(f: jrnc)], {cpu in ()}),
    opCode("JRC e", 0xFF, 0x38, 2, [mrNpc(f: jrc)], {cpu in ()}),

    opCode("JP nn", 0xFF, 0xC3, 3, [mrNNpc(f: {cpu in cpu.regs.PC = cpu.fetched.nn })], {cpu in ()}),

    opCode("RLCA", 0xFF, 0x07, 1, [], rlca),
    opCode("RLA", 0xFF, 0x17, 1, [], rla),
    opCode("RRCA", 0xFF, 0x0F, 1, [], rrca),
    opCode("RRA", 0xFF, 0x1F, 1, [], rra),

    opCode("OUT (n), A", 0xFF, 0xD3, 2, [mrNpc(f: {cpu in ()}), Exec(l: 1, f: outNa)], {cpu in ()}),
    opCode("IN A, (n)", 0xFF, 0xDB, 2, [mrNpc(f: inAn)], {cpu in ()}),

    opCode("EX (SP), IX", 0xFF, 0xE3, 1, [], exSP),
    opCode("JP HL", 0xFF, 0xE9, 1, [], {cpu in cpu.regs.PC = cpu.regs.HL }),
    opCode("EX DE, HL", 0xFF, 0xEB, 1, [], exDEhl),

    opCode("XOR *", 0xFF, 0xEE, 2, [mrNpc(f: {cpu in cpu.xor(cpu.fetched.n)})], {cpu in ()}),
    opCode("DI", 0xFF, 0xF3, 1, [], {cpu in cpu.regs.IFF1 = false; cpu.regs.IFF2 = false }),
    opCode("EI", 0xFF, 0xFb, 1, [], {cpu in cpu.regs.IFF1 = true; cpu.regs.IFF2 = true }),
    opCode("LD SP, HL", 0xFF, 0xF9, 1, [Exec(l: 2, f: {cpu in cpu.regs.SP = (cpu.regs.HL) })], {cpu in ()}),
    opCode("CP *", 0xFF, 0xFe, 2, [mrNpc(f: {cpu in cpu.cp(cpu.fetched.n)})], {cpu in ()}),

    opCode("CB", 0xFF, 0xCB, 1, [], {cpu in cpu.decodeCB()}),
    opCode("DD", 0xFF, 0xDD, 1, [], {cpu in cpu.decodeDD()}),
    opCode("ED", 0xFF, 0xED, 1, [], {cpu in cpu.decodeED()}),
    opCode("ED", 0xFF, 0xFD, 1, [], {cpu in cpu.decodeFD()}),
]

var z80OpsCodeTableCB :[opCode] = [
    opCode("RLC r", 0b11111000, 0b00000000, 1, [], cbR),
    opCode("RLC (HL)", 0xFF, 0x06, 1, [Exec(l: 1, f: cbHL)], {cpu in ()}),
    opCode("RRC r", 0b11111000, 0b00001000, 1, [], cbR),
    opCode("RRC (HL)", 0xFF, 0x0e, 1, [Exec(l: 1, f: cbHL)], {cpu in ()}),

    opCode("RL r", 0b11111000, 0b00010000, 1, [], cbR),
    opCode("RL (HL)", 0xFF, 0x16, 1, [Exec(l: 1, f: cbHL)], {cpu in ()}),
    opCode("RR r", 0b11111000, 0b00011000, 1, [], cbR),
    opCode("RR (HL)", 0xFF, 0x1e, 1, [Exec(l: 1, f: cbHL)], {cpu in ()}),

    opCode("SLA r", 0b11111000, 0b00100000, 1, [], cbR),
    opCode("SLA (HL)", 0xFF, 0x26, 1, [Exec(l: 1, f: cbHL)], {cpu in ()}),
    opCode("SRA r", 0b11111000, 0b00101000, 1, [], cbR),
    opCode("SRA (HL)", 0xFF, 0x2e, 1, [Exec(l: 1, f: cbHL)], {cpu in ()}),

    opCode("SLL r", 0b11111000, 0b00110000, 1, [], cbR),
    opCode("SLL (HL)", 0xFF, 0x36, 1, [Exec(l: 1, f: cbHL)], {cpu in ()}),
    opCode("SRL r", 0b11111000, 0b00111000, 1, [], cbR),
    opCode("SRL (HL)", 0xFF, 0x3e, 1, [Exec(l: 1, f: cbHL)], {cpu in ()}),

    opCode("BIT b, r", 0b11000000, 0b01000000, 1, [], bit),
    opCode("BIT b, (HL)", 0b11000111, 0b01000110, 1, [Exec(l: 1, f: bitHL)], {cpu in ()}),

    opCode("RES b, r", 0b11000000, 0b10000000, 1, [], res),
    opCode("RES b, (HL)", 0b11000111, 0b10000110, 1, [Exec(l: 1, f: resHL)], {cpu in ()}),

    opCode("SET b, r", 0b11000000, 0b11000000, 1, [], set),
    opCode("SET b, (HL)", 0b11000111, 0b11000110, 1, [Exec(l: 1, f: setHL)], {cpu in ()}),
]

var z80OpsCodeTableDD :[opCode] = [
    opCode("LD r, r'", 0b11000000, 0b01000000, 1, [], ldRr),
    opCode("ADD IX, rr", 0b11001111, 0b00001001, 1, [Exec(l: 7, f: addIXY)], {cpu in ()}),
    opCode("LD IX, nn", 0xFF, 0x21, 3, [mrNNpc(f: {cpu in cpu.regs.IXH = cpu.fetched.n2; cpu.regs.IXL = cpu.fetched.n})], {cpu in ()}),
    opCode("LD (nn), IX", 0xFF, 0x22, 3, [mrNNpc(f: ldNNIXY)], {cpu in ()}),
    opCode("INC IX", 0xFF, 0x23, 1, [Exec(l: 2, f: {cpu in cpu.regs.IX = (cpu.regs.IX &+ 1)})], {cpu in ()}),
    opCode("INC IXH", 0xFF, 0x24, 1, [], incIXH),
    opCode("DEC IXH", 0xFF, 0x25, 1, [], decIXH),
    opCode("LD IXH, n", 0xFF, 0x26, 2, [mrNpc(f: {cpu in cpu.regs.IXH = cpu.fetched.n})], {cpu in ()}),
    opCode("LD IX, (nn)", 0xFF, 0x2A, 3, [mrNNpc(f: ldIXYnn)], {cpu in ()}),
    opCode("DEC IX", 0xFF, 0x2B, 1, [Exec(l: 2, f: {cpu in cpu.regs.IX = (cpu.regs.IX &- 1)})], {cpu in ()}),
    opCode("INC IXL", 0xFF, 0x2C, 1, [], incIXL),
    opCode("DEC IXL", 0xFF, 0x2D, 1, [], decIXL),
    opCode("LD IXL, n", 0xFF, 0x2E, 2, [mrNpc(f: {cpu in cpu.regs.IXL = cpu.fetched.n})], {cpu in ()}),
    opCode("INC (IX+d)", 0xFF, 0x34, 2, [mrNpc(f:{cpu in ()}), Exec(l: 6, f: incIXYd)], {cpu in ()}),
    opCode("DEC (IX+d)", 0xFF, 0x35, 2, [mrNpc(f:{cpu in ()}), Exec(l: 6, f: decIXYd)], {cpu in ()}),
    opCode("LD (IX+d), n", 0xFF, 0x36, 3, [mrNNpc(f:{cpu in ()}), Exec(l: 2, f: ldIXYdN)], {cpu in ()}),

    opCode("LD B, IXH", 0xFF, 0x44, 1, [], {cpu in cpu.regs.B = cpu.regs.IXH }),
    opCode("LD B, IXL", 0xFF, 0x45, 1, [], {cpu in cpu.regs.B = cpu.regs.IXL }),
    opCode("LD C, IXH", 0xFF, 0x4C, 1, [], {cpu in cpu.regs.C = cpu.regs.IXH }),
    opCode("LD C, IXL", 0xFF, 0x4D, 1, [], {cpu in cpu.regs.C = cpu.regs.IXL }),
    opCode("LD D, IXH", 0xFF, 0x54, 1, [], {cpu in cpu.regs.D = cpu.regs.IXH }),
    opCode("LD D, IXL", 0xFF, 0x55, 1, [], {cpu in cpu.regs.D = cpu.regs.IXL }),
    opCode("LD E, IXH", 0xFF, 0x5C, 1, [], {cpu in cpu.regs.E = cpu.regs.IXH }),
    opCode("LD E, IXL", 0xFF, 0x5D, 1, [], {cpu in cpu.regs.E = cpu.regs.IXL }),
    opCode("LD A, IXH", 0xFF, 0x7C, 1, [], {cpu in cpu.regs.A = cpu.regs.IXH }),
    opCode("LD A, IXL", 0xFF, 0x7D, 1, [], {cpu in cpu.regs.A = cpu.regs.IXL }),

    opCode("LD IXH, r", 0b11111000, 0b01100000, 1, [], ldIXYHr),
    opCode("LD IXH, r", 0b11111000, 0b01101000, 1, [], ldIXYLr),
    opCode("LD r, (IX+d)", 0b11000111, 0b01000110, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: ldRixyD)], {cpu in ()}),
    opCode("LD (IX+d), r", 0b11111000, 0b01110000, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: ldIXYdR)], {cpu in ()}),

    opCode("ADD A, IXH", 0xFF, 0x84, 1, [], {cpu in cpu.addA(cpu.regs.IXH) }),
    opCode("ADD A, IXL", 0xFF, 0x85, 1, [], {cpu in cpu.addA(cpu.regs.IXL) }),
    opCode("ADC A, IXH", 0xFF, 0x8C, 1, [], {cpu in cpu.adcA(cpu.regs.IXH) }),
    opCode("ADC A, IXL", 0xFF, 0x8D, 1, [], {cpu in cpu.adcA(cpu.regs.IXL) }),
    opCode("SUB A, IXH", 0xFF, 0x94, 1, [], {cpu in cpu.subA(cpu.regs.IXH) }),
    opCode("SUB A, IXL", 0xFF, 0x95, 1, [], {cpu in cpu.subA(cpu.regs.IXL) }),
    opCode("SBC A, IXH", 0xFF, 0x9C, 1, [], {cpu in cpu.sbcA(cpu.regs.IXH) }),
    opCode("SBC A, IXL", 0xFF, 0x9D, 1, [], {cpu in cpu.sbcA(cpu.regs.IXL) }),
    opCode("AND A, IXH", 0xFF, 0xA4, 1, [], {cpu in cpu.and(cpu.regs.IXH) }),
    opCode("AND A, IXL", 0xFF, 0xA5, 1, [], {cpu in cpu.and(cpu.regs.IXL) }),
    opCode("XOR A, IXH", 0xFF, 0xAC, 1, [], {cpu in cpu.xor(cpu.regs.IXH) }),
    opCode("XOR A, IXL", 0xFF, 0xAD, 1, [], {cpu in cpu.xor(cpu.regs.IXL) }),
    opCode("OR A, IXH", 0xFF, 0xB4, 1, [], {cpu in cpu.or(cpu.regs.IXH) }),
    opCode("OR A, IXL", 0xFF, 0xB5, 1, [], {cpu in cpu.or(cpu.regs.IXL) }),
    opCode("CP A, IXH", 0xFF, 0xBC, 1, [], {cpu in cpu.cp(cpu.regs.IXH) }),
    opCode("CP A, IXL", 0xFF, 0xBD, 1, [], {cpu in cpu.cp(cpu.regs.IXL) }),

    opCode("ADD A, (IX+d)", 0xFF, 0x86, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: addAixyD)], {cpu in ()}),
    opCode("ADC A, (IX+d)", 0xFF, 0x8E, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: adcAixyD)], {cpu in ()}),
    opCode("SUB A, (IX+d)", 0xFF, 0x96, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: subAixyD)], {cpu in ()}),
    opCode("SBC A, (IX+d)", 0xFF, 0x9E, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: sbcAixyD)], {cpu in ()}),
    opCode("AND A, (IX+d)", 0xFF, 0xA6, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: andAixyD)], {cpu in ()}),
    opCode("XOR A, (IX+d)", 0xFF, 0xAE, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: xorAixyD)], {cpu in ()}),
    opCode("OR A, (IX+d)", 0xFF, 0xB6, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: orAixyD)], {cpu in ()}),
    opCode("CP A, (IX+d)", 0xFF, 0xBE, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: cpAixyD)], {cpu in ()}),

    opCode("CB", 0xFF, 0xCB, 2, [mrNpc(f: {cpu in cpu.decodeDDCB()})], {cpu in ()}),

    opCode("POP IX", 0xFF, 0xE1, 1, [], {cpu in cpu.popFromStack({cpu,data in cpu.regs.IX = (data)})}),
    opCode("EX (SP), IX", 0xFF, 0xE3, 1, [], exSP),
    opCode("PUSH IX", 0xFF, 0xE5, 1, [Exec(l: 1, f: {cpu in cpu.pushToStack(cpu.regs.IX, {cpu in ()})})], {cpu in ()}),
    opCode("JP IX", 0xFF, 0xE9, 1, [], {cpu in cpu.regs.PC = cpu.regs.IX }),
    opCode("LD SP, IX", 0xFF, 0xF9, 1, [Exec(l: 2, f: {cpu in cpu.regs.SP = (cpu.regs.IX)})], {cpu in ()}),
]

var z80OpsCodeTableFD :[opCode] = [
    opCode("LD r, r'", 0b11000000, 0b01000000, 1, [], ldRr),
    opCode("ADD IY, rr", 0b11001111, 0b00001001, 1, [Exec(l: 7, f: addIXY)], {cpu in ()}),
    opCode("LD IY, nn", 0xFF, 0x21, 3, [mrNNpc(f: {cpu in cpu.regs.IYH = cpu.fetched.n2; cpu.regs.IYL = cpu.fetched.n})], {cpu in ()}),
    opCode("LD (nn), IY", 0xFF, 0x22, 3, [mrNNpc(f: ldNNIXY)], {cpu in ()}),
    opCode("INC IY", 0xFF, 0x23, 1, [Exec(l: 2, f: {cpu in cpu.regs.IY = (cpu.regs.IY &+ 1)})], {cpu in ()}),
    opCode("INC IYH", 0xFF, 0x24, 1, [], incIYH),
    opCode("DEC IYH", 0xFF, 0x25, 1, [], decIYH),
    opCode("LD IYH, n", 0xFF, 0x26, 2, [mrNpc(f: {cpu in cpu.regs.IYH = cpu.fetched.n})], {cpu in ()}),
    opCode("LD IY, (nn)", 0xFF, 0x2A, 3, [mrNNpc(f: ldIXYnn)], {cpu in ()}),
    opCode("DEC IY", 0xFF, 0x2B, 1, [Exec(l: 2, f: {cpu in cpu.regs.IY = (cpu.regs.IY &- 1)})], {cpu in ()}),
    opCode("INC IYL", 0xFF, 0x2C, 1, [], incIYL),
    opCode("DEC IYL", 0xFF, 0x2D, 1, [], decIYL),
    opCode("LD IYL, n", 0xFF, 0x2E, 2, [mrNpc(f: {cpu in cpu.regs.IYL = cpu.fetched.n})], {cpu in ()}),
    opCode("INC (IY+d)", 0xFF, 0x34, 2, [mrNpc(f:{cpu in ()}), Exec(l: 6, f: incIXYd)], {cpu in ()}),
    opCode("DEC (IY+d)", 0xFF, 0x35, 2, [mrNpc(f:{cpu in ()}), Exec(l: 6, f: decIXYd)], {cpu in ()}),
    opCode("LD (IY+d), n", 0xFF, 0x36, 3, [mrNNpc(f:{cpu in ()}), Exec(l: 2, f: ldIXYdN)], {cpu in ()}),

    opCode("LD B, IYH", 0xFF, 0x44, 1, [], {cpu in cpu.regs.B = cpu.regs.IYH }),
    opCode("LD B, IYL", 0xFF, 0x45, 1, [], {cpu in cpu.regs.B = cpu.regs.IYL }),
    opCode("LD C, IYH", 0xFF, 0x4C, 1, [], {cpu in cpu.regs.C = cpu.regs.IYH }),
    opCode("LD C, IYL", 0xFF, 0x4D, 1, [], {cpu in cpu.regs.C = cpu.regs.IYL }),
    opCode("LD D, IYH", 0xFF, 0x54, 1, [], {cpu in cpu.regs.D = cpu.regs.IYH }),
    opCode("LD D, IYL", 0xFF, 0x55, 1, [], {cpu in cpu.regs.D = cpu.regs.IYL }),
    opCode("LD E, IYH", 0xFF, 0x5C, 1, [], {cpu in cpu.regs.E = cpu.regs.IYH }),
    opCode("LD E, IYL", 0xFF, 0x5D, 1, [], {cpu in cpu.regs.E = cpu.regs.IYL }),
    opCode("LD A, IYH", 0xFF, 0x7C, 1, [], {cpu in cpu.regs.A = cpu.regs.IYH }),
    opCode("LD A, IYL", 0xFF, 0x7D, 1, [], {cpu in cpu.regs.A = cpu.regs.IYL }),

    opCode("LD IYH, r", 0b11111000, 0b01100000, 1, [], ldIXYHr),
    opCode("LD IYL, r", 0b11111000, 0b01101000, 1, [], ldIXYLr),
    opCode("LD r, (IY+d)", 0b11000111, 0b01000110, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: ldRixyD)], {cpu in ()}),
    opCode("LD (IY+d), r", 0b11111000, 0b01110000, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: ldIXYdR)], {cpu in ()}),

    opCode("ADD A, IYH", 0xFF, 0x84, 1, [], {cpu in cpu.addA(cpu.regs.IYH) }),
    opCode("ADD A, IYL", 0xFF, 0x85, 1, [], {cpu in cpu.addA(cpu.regs.IYL) }),
    opCode("ADC A, IYH", 0xFF, 0x8C, 1, [], {cpu in cpu.adcA(cpu.regs.IYH) }),
    opCode("ADC A, IYL", 0xFF, 0x8D, 1, [], {cpu in cpu.adcA(cpu.regs.IYL) }),
    opCode("SUB A, IYH", 0xFF, 0x94, 1, [], {cpu in cpu.subA(cpu.regs.IYH) }),
    opCode("SUB A, IYL", 0xFF, 0x95, 1, [], {cpu in cpu.subA(cpu.regs.IYL) }),
    opCode("SBC A, IYH", 0xFF, 0x9C, 1, [], {cpu in cpu.sbcA(cpu.regs.IYH) }),
    opCode("SBC A, IYL", 0xFF, 0x9D, 1, [], {cpu in cpu.sbcA(cpu.regs.IYL) }),
    opCode("AND A, IYH", 0xFF, 0xA4, 1, [], {cpu in cpu.and(cpu.regs.IYH) }),
    opCode("AND A, IYL", 0xFF, 0xA5, 1, [], {cpu in cpu.and(cpu.regs.IYL) }),
    opCode("XOR A, IYH", 0xFF, 0xAC, 1, [], {cpu in cpu.xor(cpu.regs.IYH) }),
    opCode("XOR A, IYL", 0xFF, 0xAD, 1, [], {cpu in cpu.xor(cpu.regs.IYL) }),
    opCode("OR A, IYH", 0xFF, 0xB4, 1, [], {cpu in cpu.or(cpu.regs.IYH) }),
    opCode("OR A, IYL", 0xFF, 0xB5, 1, [], {cpu in cpu.or(cpu.regs.IYL) }),
    opCode("CP A, IYH", 0xFF, 0xBC, 1, [], {cpu in cpu.cp(cpu.regs.IYH) }),
    opCode("CP A, IYL", 0xFF, 0xBD, 1, [], {cpu in cpu.cp(cpu.regs.IYL) }),

    opCode("ADD A, (IY+d)", 0xFF, 0x86, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: addAixyD)], {cpu in ()}),
    opCode("ADC A, (IY+d)", 0xFF, 0x8E, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: adcAixyD)], {cpu in ()}),
    opCode("SUB A, (IY+d)", 0xFF, 0x96, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: subAixyD)], {cpu in ()}),
    opCode("SBC A, (IY+d)", 0xFF, 0x9E, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: sbcAixyD)], {cpu in ()}),
    opCode("AND A, (IY+d)", 0xFF, 0xA6, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: andAixyD)], {cpu in ()}),
    opCode("XOR A, (IY+d)", 0xFF, 0xAE, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: xorAixyD)], {cpu in ()}),
    opCode("OR A, (IY+d)", 0xFF, 0xB6, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: orAixyD)], {cpu in ()}),
    opCode("CP A, (IY+d)", 0xFF, 0xBE, 2, [mrNpc(f:{cpu in ()}), Exec(l: 5, f: cpAixyD)], {cpu in ()}),

    opCode("CB", 0xFF, 0xCB, 2, [mrNpc(f: {cpu in cpu.decodeFDCB()})], {cpu in ()}),

    opCode("POP IY", 0xFF, 0xE1, 1, [], {cpu in cpu.popFromStack({cpu,data in cpu.regs.IY = (data) }) }),
    opCode("EX (SP), IY", 0xFF, 0xE3, 1, [], exSP),
    opCode("PUSH IY", 0xFF, 0xE5, 1, [Exec(l: 1, f: {cpu in cpu.pushToStack(cpu.regs.IY, {cpu in ()})})], {cpu in ()}),
    opCode("JP IY", 0xFF, 0xE9, 1, [], {cpu in cpu.regs.PC = cpu.regs.IY }),
    opCode("LD SP, IY", 0xFF, 0xF9, 1, [Exec(l: 2, f: {cpu in cpu.regs.SP = (cpu.regs.IY)})], {cpu in ()}),
]

var z80OpsCodeTableDDCB :[opCode] = [
    opCode("RLC (IX+d), r", 0b11111000, 0b00000000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("RLC (IX+d)", 0xFF, 0x06, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),
    opCode("RRC (IX+d), r", 0b11111000, 0b00001000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("RRC (IX+d)", 0xFF, 0x0e, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),

    opCode("RL (IX+d), r", 0b11111000, 0b00010000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("RL (IX+d)", 0xFF, 0x16, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),
    opCode("RR (IX+d), r", 0b11111000, 0b00011000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("RR (IX+d)", 0xFF, 0x1e, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),

    opCode("SLA (IX+d), r", 0b11111000, 0b00100000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("SLA (IX+d)", 0xFF, 0x26, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),
    opCode("SRA (IX+d), r", 0b11111000, 0b00101000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("SRA (IX+d)", 0xFF, 0x2e, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),

    opCode("SLL (IX+d), r", 0b11111000, 0b00110000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("SLL (IX+d)", 0xFF, 0x36, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),
    opCode("SRL (IX+d), r", 0b11111000, 0b00111000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("SRL (IX+d)", 0xFF, 0x3e, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),

    opCode("BIT b, (IX+d), r", 0b11000000, 0b01000000, 1, [Exec(l: 2, f: bitIXYd)], {cpu in ()}),
    opCode("BIT b, (IX+d)", 0b11000111, 0b01000110, 1, [Exec(l: 2, f: bitIXYd)], {cpu in ()}),

    opCode("RES b, (IX+d), r", 0b11000000, 0b10000000, 1, [Exec(l: 2, f: resIXYdR)], {cpu in ()}),
    opCode("RES b, (IX+d)", 0b11000111, 0b10000110, 1, [Exec(l: 2, f: resIXYd)], {cpu in ()}),

    opCode("SET b, (IX+d), r", 0b11000000, 0b11000000, 1, [Exec(l: 2, f: setIXYdR)], {cpu in ()}),
    opCode("SET b, (IX+d)", 0b11000111, 0b11000110, 1, [Exec(l: 2, f: setIXYd)], {cpu in ()}),
]

var z80OpsCodeTableFDCB :[opCode] = [
    opCode("RLC (IY+d), r", 0b11111000, 0b00000000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("RLC (IY+d)", 0xFF, 0x06, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),
    opCode("RRC (IY+d), r", 0b11111000, 0b00001000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("RRC (IY+d)", 0xFF, 0x0e, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),

    opCode("RL (IY+d), r", 0b11111000, 0b00010000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("RL (IY+d)", 0xFF, 0x16, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),
    opCode("RR (IY+d), r", 0b11111000, 0b00011000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("RR (IY+d)", 0xFF, 0x1e, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),

    opCode("SLA (IY+d), r", 0b11111000, 0b00100000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("SLA (IY+d)", 0xFF, 0x26, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),
    opCode("SRA (IY+d), r", 0b11111000, 0b00101000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("SRA (IY+d)", 0xFF, 0x2e, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),

    opCode("SLL (IY+d), r", 0b11111000, 0b00110000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("SLL (IY+d)", 0xFF, 0x36, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),
    opCode("SRL (IY+d), r", 0b11111000, 0b00111000, 1, [Exec(l: 2, f: cbIXYdr)], {cpu in ()}),
    opCode("SRL (IY+d)", 0xFF, 0x3e, 1, [Exec(l: 2, f: cbIXYd)], {cpu in ()}),

    opCode("BIT b, (IY+d), r", 0b11000000, 0b01000000, 1, [Exec(l: 2, f: bitIXYd)], {cpu in ()}),
    opCode("BIT b, (IY+d)", 0b11000111, 0b01000110, 1, [Exec(l: 2, f: bitIXYd)], {cpu in ()}),

    opCode("RES b, (IY+d), r", 0b11000000, 0b10000000, 1, [Exec(l: 2, f: resIXYdR)], {cpu in ()}),
    opCode("RES b, (IY+d)", 0b11000111, 0b10000110, 1, [Exec(l: 2, f: resIXYd)], {cpu in ()}),

    opCode("SET b, (IY+d), r", 0b11000000, 0b11000000, 1, [Exec(l: 2, f: setIXYdR)], {cpu in ()}),
    opCode("SET b, (IY+d)", 0b11000111, 0b11000110, 1, [Exec(l: 2, f: setIXYd)], {cpu in ()}),
]

var z80OpsCodeTableED :[opCode] = [
    opCode("IN r, (c)", 0b11000111, 0b01000000, 1, [], inRc),
    opCode("IN (c)", 0xFF, 0x70, 1, [], inC),
    opCode("OUT (c), r", 0b11000111, 0b01000001, 1, [Exec(l: 1, f: outCr)], {cpu in ()}),
    opCode("OUT (c), 0", 0xFF, 0x71, 1, [Exec(l: 1, f: outC0)], {cpu in ()}),

    opCode("SBC HL, BC", 0xFF, 0x42, 1, [Exec(l: 7, f: {cpu in cpu.sbcHL(cpu.regs.BC)})], {cpu in ()}),
    opCode("SBC HL, DE", 0xFF, 0x52, 1, [Exec(l: 7, f: {cpu in cpu.sbcHL(cpu.regs.DE)})], {cpu in ()}),
    opCode("SBC HL, HL", 0xFF, 0x62, 1, [Exec(l: 7, f: {cpu in cpu.sbcHL(cpu.regs.HL)})], {cpu in ()}),
    opCode("SBC HL, SP", 0xFF, 0x72, 1, [Exec(l: 7, f: {cpu in cpu.sbcHL(cpu.regs.SP)})], {cpu in ()}),

    opCode("LD (nn), dd", 0b11001111, 0b01000011, 3, [mrNNpc(f: ldNNdd)], {cpu in ()}),
    opCode("LD dd, (nn)", 0b11001111, 0b01001011, 3, [mrNNpc(f: ldDDnn)], {cpu in ()}),
    opCode("NEG", 0b11000111, 0b01000100, 1, [], {cpu in var n = cpu.regs.A; cpu.regs.A = 0; cpu.subA(n) }),
    opCode("RETN", 0b11000111, 0b01000101, 1, [], {cpu in cpu.regs.IFF1 = cpu.regs.IFF2; ret(cpu: cpu) }),

    opCode("IM 0", 0xFF, 0x46, 1, [], {cpu in cpu.regs.InterruptsMode = 0 }),
    opCode("IM 0", 0xFF, 0x66, 1, [], {cpu in cpu.regs.InterruptsMode = 0 }),
    opCode("IM 1", 0xFF, 0x56, 1, [], {cpu in cpu.regs.InterruptsMode = 1 }),
    opCode("IM 2", 0xFF, 0xE5, 1, [], {cpu in cpu.regs.InterruptsMode = 2 }),
    opCode("IM 0/1", 0xFF, 0x4E, 1, [], {cpu in cpu.regs.InterruptsMode = 0 }),
    opCode("IM 2", 0xFF, 0x5E, 1, [], {cpu in cpu.regs.InterruptsMode = 2 }),
    opCode("IM 0/1", 0xFF, 0x6E, 1, [], {cpu in cpu.regs.InterruptsMode = 0 }),
    opCode("IM 1", 0xFF, 0x76, 1, [], {cpu in cpu.regs.InterruptsMode = 1 }),
    opCode("IM 2", 0xFF, 0x7E, 1, [], {cpu in cpu.regs.InterruptsMode = 2 }),

    opCode("LD I, A", 0xFF, 0x47, 1, [Exec(l: 1, f: {cpu in cpu.regs.I = cpu.regs.A})], {cpu in ()}),
    opCode("LD R, A", 0xFF, 0x4F, 1, [Exec(l: 1, f: {cpu in cpu.regs.R = cpu.regs.A})], {cpu in ()}),

    opCode("LD A, I", 0xFF, 0x57, 1, [Exec(l: 1, f: ldAi)], {cpu in ()}),
    opCode("LD A, R", 0xFF, 0x5F, 1, [Exec(l: 1, f: ldAr)], {cpu in ()}),

    opCode("ADC HL, BC", 0xFF, 0x4a, 1, [Exec(l: 7, f: {cpu in cpu.adcHL(cpu.regs.BC)})], {cpu in ()}),
    opCode("ADC HL, DE", 0xFF, 0x5a, 1, [Exec(l: 7, f: {cpu in cpu.adcHL(cpu.regs.DE)})], {cpu in ()}),
    opCode("ADC HL, HL", 0xFF, 0x6a, 1, [Exec(l: 7, f: {cpu in cpu.adcHL(cpu.regs.HL)})], {cpu in ()}),
    opCode("ADC HL, SP", 0xFF, 0x7a, 1, [Exec(l: 7, f: {cpu in cpu.adcHL(cpu.regs.SP)})], {cpu in ()}),


    opCode("RDD", 0xFF, 0x67, 1, [], rrd),
    opCode("RDD", 0xFF, 0x6f, 1, [], rld),

    opCode("LDI", 0xFF, 0xA0, 1, [], ldi),
    opCode("CPI", 0xFF, 0xA1, 1, [], cpi),
    opCode("INI", 0xFF, 0xA2, 1, [], ini),
    opCode("OUTI", 0xFF, 0xA3, 1, [], outi),

    opCode("LDD", 0xFF, 0xA8, 1, [], ldd),
    opCode("CPD", 0xFF, 0xA9, 1, [], cpd),
    opCode("IND", 0xFF, 0xAA, 1, [], ind),
    opCode("OUTD", 0xFF, 0xAB, 1, [], outd),

    opCode("LDIR", 0xFF, 0xB0, 1, [], ldi),
    opCode("CPIR", 0xFF, 0xB1, 1, [], cpi),
    opCode("INIR", 0xFF, 0xB2, 1, [], ini),
    opCode("OTIR", 0xFF, 0xB3, 1, [], outi),

    opCode("LDDR", 0xFF, 0xB8, 1, [], ldd),
    opCode("CPDR", 0xFF, 0xB9, 1, [], cpd),
    opCode("INDR", 0xFF, 0xBA, 1, [], ind),
    opCode("OTDR", 0xFF, 0xBB, 1, [], outd),
]

