#include "kernel.h"
.code32
.text

# handler
.text
.globl vector0
vector0:
  pushl $0
  pushl $0
  jmp idt_handler_common
.globl vector1
vector1:
  pushl $0
  pushl $1
  jmp idt_handler_common
.globl vector2
vector2:
  pushl $0
  pushl $2
  jmp idt_handler_common
.globl vector3
vector3:
  pushl $0
  pushl $3
  jmp idt_handler_common
.globl vector4
vector4:
  pushl $0
  pushl $4
  jmp idt_handler_common
.globl vector5
vector5:
  pushl $0
  pushl $5
  jmp idt_handler_common
.globl vector6
vector6:
  pushl $0
  pushl $6
  jmp idt_handler_common
.globl vector7
vector7:
  pushl $0
  pushl $7
  jmp idt_handler_common
.globl vector8
vector8:
  pushl $8
  jmp idt_handler_common
.globl vector9
vector9:
  pushl $9
  jmp idt_handler_common
.globl vector10
vector10:
  pushl $10
  jmp idt_handler_common
.globl vector11
vector11:
  pushl $11
  jmp idt_handler_common
.globl vector12
vector12:
  pushl $12
  jmp idt_handler_common
.globl vector13
vector13:
  pushl $13
  jmp idt_handler_common
.globl vector14
vector14:
  pushl $14
  jmp idt_handler_common
.globl vector15
vector15:
  pushl $0
  pushl $15
  jmp idt_handler_common
.globl vector16
vector16:
  pushl $0
  pushl $16
  jmp idt_handler_common
.globl vector17
vector17:
  pushl $17
  jmp idt_handler_common
.globl vector18
vector18:
  pushl $0
  pushl $18
  jmp idt_handler_common
.globl vector19
vector19:
  pushl $0
  pushl $19
  jmp idt_handler_common
.globl vector20
vector20:
  pushl $0
  pushl $20
  jmp idt_handler_common
.globl vector21
vector21:
  pushl $0
  pushl $21
  jmp idt_handler_common
.globl vector22
vector22:
  pushl $0
  pushl $22
  jmp idt_handler_common
.globl vector23
vector23:
  pushl $0
  pushl $23
  jmp idt_handler_common
.globl vector24
vector24:
  pushl $0
  pushl $24
  jmp idt_handler_common
.globl vector25
vector25:
  pushl $0
  pushl $25
  jmp idt_handler_common
.globl vector26
vector26:
  pushl $0
  pushl $26
  jmp idt_handler_common
.globl vector27
vector27:
  pushl $0
  pushl $27
  jmp idt_handler_common
.globl vector28
vector28:
  pushl $0
  pushl $28
  jmp idt_handler_common
.globl vector29
vector29:
  pushl $0
  pushl $29
  jmp idt_handler_common
.globl vector30
vector30:
  pushl $0
  pushl $30
  jmp idt_handler_common
.globl vector31
vector31:
  pushl $0
  pushl $31
  jmp idt_handler_common
.globl vector32
vector32:
  pushl $0
  pushl $32
  jmp idt_handler_common
.globl vector33
vector33:
  pushl $0
  pushl $33
  jmp idt_handler_common
.globl vector34
vector34:
  pushl $0
  pushl $34
  jmp idt_handler_common
.globl vector35
vector35:
  pushl $0
  pushl $35
  jmp idt_handler_common
.globl vector36
vector36:
  pushl $0
  pushl $36
  jmp idt_handler_common
.globl vector37
vector37:
  pushl $0
  pushl $37
  jmp idt_handler_common
.globl vector38
vector38:
  pushl $0
  pushl $38
  jmp idt_handler_common
.globl vector39
vector39:
  pushl $0
  pushl $39
  jmp idt_handler_common
.globl vector40
vector40:
  pushl $0
  pushl $40
  jmp idt_handler_common
.globl vector41
vector41:
  pushl $0
  pushl $41
  jmp idt_handler_common
.globl vector42
vector42:
  pushl $0
  pushl $42
  jmp idt_handler_common
.globl vector43
vector43:
  pushl $0
  pushl $43
  jmp idt_handler_common
.globl vector44
vector44:
  pushl $0
  pushl $44
  jmp idt_handler_common
.globl vector45
vector45:
  pushl $0
  pushl $45
  jmp idt_handler_common
.globl vector46
vector46:
  pushl $0
  pushl $46
  jmp idt_handler_common
.globl vector47
vector47:
  pushl $0
  pushl $47
  jmp idt_handler_common
.globl vector48
vector48:
  pushl $0
  pushl $48
  jmp idt_handler_common
.globl vector49
vector49:
  pushl $0
  pushl $49
  jmp idt_handler_common
.globl vector50
vector50:
  pushl $0
  pushl $50
  jmp idt_handler_common
.globl vector51
vector51:
  pushl $0
  pushl $51
  jmp idt_handler_common
.globl vector52
vector52:
  pushl $0
  pushl $52
  jmp idt_handler_common
.globl vector53
vector53:
  pushl $0
  pushl $53
  jmp idt_handler_common
.globl vector54
vector54:
  pushl $0
  pushl $54
  jmp idt_handler_common
.globl vector55
vector55:
  pushl $0
  pushl $55
  jmp idt_handler_common
.globl vector56
vector56:
  pushl $0
  pushl $56
  jmp idt_handler_common
.globl vector57
vector57:
  pushl $0
  pushl $57
  jmp idt_handler_common
.globl vector58
vector58:
  pushl $0
  pushl $58
  jmp idt_handler_common
.globl vector59
vector59:
  pushl $0
  pushl $59
  jmp idt_handler_common
.globl vector60
vector60:
  pushl $0
  pushl $60
  jmp idt_handler_common
.globl vector61
vector61:
  pushl $0
  pushl $61
  jmp idt_handler_common
.globl vector62
vector62:
  pushl $0
  pushl $62
  jmp idt_handler_common
.globl vector63
vector63:
  pushl $0
  pushl $63
  jmp idt_handler_common
.globl vector64
vector64:
  pushl $0
  pushl $64
  jmp idt_handler_common
.globl vector65
vector65:
  pushl $0
  pushl $65
  jmp idt_handler_common
.globl vector66
vector66:
  pushl $0
  pushl $66
  jmp idt_handler_common
.globl vector67
vector67:
  pushl $0
  pushl $67
  jmp idt_handler_common
.globl vector68
vector68:
  pushl $0
  pushl $68
  jmp idt_handler_common
.globl vector69
vector69:
  pushl $0
  pushl $69
  jmp idt_handler_common
.globl vector70
vector70:
  pushl $0
  pushl $70
  jmp idt_handler_common
.globl vector71
vector71:
  pushl $0
  pushl $71
  jmp idt_handler_common
.globl vector72
vector72:
  pushl $0
  pushl $72
  jmp idt_handler_common
.globl vector73
vector73:
  pushl $0
  pushl $73
  jmp idt_handler_common
.globl vector74
vector74:
  pushl $0
  pushl $74
  jmp idt_handler_common
.globl vector75
vector75:
  pushl $0
  pushl $75
  jmp idt_handler_common
.globl vector76
vector76:
  pushl $0
  pushl $76
  jmp idt_handler_common
.globl vector77
vector77:
  pushl $0
  pushl $77
  jmp idt_handler_common
.globl vector78
vector78:
  pushl $0
  pushl $78
  jmp idt_handler_common
.globl vector79
vector79:
  pushl $0
  pushl $79
  jmp idt_handler_common
.globl vector80
vector80:
  pushl $0
  pushl $80
  jmp idt_handler_common
.globl vector81
vector81:
  pushl $0
  pushl $81
  jmp idt_handler_common
.globl vector82
vector82:
  pushl $0
  pushl $82
  jmp idt_handler_common
.globl vector83
vector83:
  pushl $0
  pushl $83
  jmp idt_handler_common
.globl vector84
vector84:
  pushl $0
  pushl $84
  jmp idt_handler_common
.globl vector85
vector85:
  pushl $0
  pushl $85
  jmp idt_handler_common
.globl vector86
vector86:
  pushl $0
  pushl $86
  jmp idt_handler_common
.globl vector87
vector87:
  pushl $0
  pushl $87
  jmp idt_handler_common
.globl vector88
vector88:
  pushl $0
  pushl $88
  jmp idt_handler_common
.globl vector89
vector89:
  pushl $0
  pushl $89
  jmp idt_handler_common
.globl vector90
vector90:
  pushl $0
  pushl $90
  jmp idt_handler_common
.globl vector91
vector91:
  pushl $0
  pushl $91
  jmp idt_handler_common
.globl vector92
vector92:
  pushl $0
  pushl $92
  jmp idt_handler_common
.globl vector93
vector93:
  pushl $0
  pushl $93
  jmp idt_handler_common
.globl vector94
vector94:
  pushl $0
  pushl $94
  jmp idt_handler_common
.globl vector95
vector95:
  pushl $0
  pushl $95
  jmp idt_handler_common
.globl vector96
vector96:
  pushl $0
  pushl $96
  jmp idt_handler_common
.globl vector97
vector97:
  pushl $0
  pushl $97
  jmp idt_handler_common
.globl vector98
vector98:
  pushl $0
  pushl $98
  jmp idt_handler_common
.globl vector99
vector99:
  pushl $0
  pushl $99
  jmp idt_handler_common
.globl vector100
vector100:
  pushl $0
  pushl $100
  jmp idt_handler_common
.globl vector101
vector101:
  pushl $0
  pushl $101
  jmp idt_handler_common
.globl vector102
vector102:
  pushl $0
  pushl $102
  jmp idt_handler_common
.globl vector103
vector103:
  pushl $0
  pushl $103
  jmp idt_handler_common
.globl vector104
vector104:
  pushl $0
  pushl $104
  jmp idt_handler_common
.globl vector105
vector105:
  pushl $0
  pushl $105
  jmp idt_handler_common
.globl vector106
vector106:
  pushl $0
  pushl $106
  jmp idt_handler_common
.globl vector107
vector107:
  pushl $0
  pushl $107
  jmp idt_handler_common
.globl vector108
vector108:
  pushl $0
  pushl $108
  jmp idt_handler_common
.globl vector109
vector109:
  pushl $0
  pushl $109
  jmp idt_handler_common
.globl vector110
vector110:
  pushl $0
  pushl $110
  jmp idt_handler_common
.globl vector111
vector111:
  pushl $0
  pushl $111
  jmp idt_handler_common
.globl vector112
vector112:
  pushl $0
  pushl $112
  jmp idt_handler_common
.globl vector113
vector113:
  pushl $0
  pushl $113
  jmp idt_handler_common
.globl vector114
vector114:
  pushl $0
  pushl $114
  jmp idt_handler_common
.globl vector115
vector115:
  pushl $0
  pushl $115
  jmp idt_handler_common
.globl vector116
vector116:
  pushl $0
  pushl $116
  jmp idt_handler_common
.globl vector117
vector117:
  pushl $0
  pushl $117
  jmp idt_handler_common
.globl vector118
vector118:
  pushl $0
  pushl $118
  jmp idt_handler_common
.globl vector119
vector119:
  pushl $0
  pushl $119
  jmp idt_handler_common
.globl vector120
vector120:
  pushl $0
  pushl $120
  jmp idt_handler_common
.globl vector121
vector121:
  pushl $0
  pushl $121
  jmp idt_handler_common
.globl vector122
vector122:
  pushl $0
  pushl $122
  jmp idt_handler_common
.globl vector123
vector123:
  pushl $0
  pushl $123
  jmp idt_handler_common
.globl vector124
vector124:
  pushl $0
  pushl $124
  jmp idt_handler_common
.globl vector125
vector125:
  pushl $0
  pushl $125
  jmp idt_handler_common
.globl vector126
vector126:
  pushl $0
  pushl $126
  jmp idt_handler_common
.globl vector127
vector127:
  pushl $0
  pushl $127
  jmp idt_handler_common
.globl vector128
vector128:
  pushl $0
  pushl $128
  jmp idt_handler_common
.globl vector129
vector129:
  pushl $0
  pushl $129
  jmp idt_handler_common
.globl vector130
vector130:
  pushl $0
  pushl $130
  jmp idt_handler_common
.globl vector131
vector131:
  pushl $0
  pushl $131
  jmp idt_handler_common
.globl vector132
vector132:
  pushl $0
  pushl $132
  jmp idt_handler_common
.globl vector133
vector133:
  pushl $0
  pushl $133
  jmp idt_handler_common
.globl vector134
vector134:
  pushl $0
  pushl $134
  jmp idt_handler_common
.globl vector135
vector135:
  pushl $0
  pushl $135
  jmp idt_handler_common
.globl vector136
vector136:
  pushl $0
  pushl $136
  jmp idt_handler_common
.globl vector137
vector137:
  pushl $0
  pushl $137
  jmp idt_handler_common
.globl vector138
vector138:
  pushl $0
  pushl $138
  jmp idt_handler_common
.globl vector139
vector139:
  pushl $0
  pushl $139
  jmp idt_handler_common
.globl vector140
vector140:
  pushl $0
  pushl $140
  jmp idt_handler_common
.globl vector141
vector141:
  pushl $0
  pushl $141
  jmp idt_handler_common
.globl vector142
vector142:
  pushl $0
  pushl $142
  jmp idt_handler_common
.globl vector143
vector143:
  pushl $0
  pushl $143
  jmp idt_handler_common
.globl vector144
vector144:
  pushl $0
  pushl $144
  jmp idt_handler_common
.globl vector145
vector145:
  pushl $0
  pushl $145
  jmp idt_handler_common
.globl vector146
vector146:
  pushl $0
  pushl $146
  jmp idt_handler_common
.globl vector147
vector147:
  pushl $0
  pushl $147
  jmp idt_handler_common
.globl vector148
vector148:
  pushl $0
  pushl $148
  jmp idt_handler_common
.globl vector149
vector149:
  pushl $0
  pushl $149
  jmp idt_handler_common
.globl vector150
vector150:
  pushl $0
  pushl $150
  jmp idt_handler_common
.globl vector151
vector151:
  pushl $0
  pushl $151
  jmp idt_handler_common
.globl vector152
vector152:
  pushl $0
  pushl $152
  jmp idt_handler_common
.globl vector153
vector153:
  pushl $0
  pushl $153
  jmp idt_handler_common
.globl vector154
vector154:
  pushl $0
  pushl $154
  jmp idt_handler_common
.globl vector155
vector155:
  pushl $0
  pushl $155
  jmp idt_handler_common
.globl vector156
vector156:
  pushl $0
  pushl $156
  jmp idt_handler_common
.globl vector157
vector157:
  pushl $0
  pushl $157
  jmp idt_handler_common
.globl vector158
vector158:
  pushl $0
  pushl $158
  jmp idt_handler_common
.globl vector159
vector159:
  pushl $0
  pushl $159
  jmp idt_handler_common
.globl vector160
vector160:
  pushl $0
  pushl $160
  jmp idt_handler_common
.globl vector161
vector161:
  pushl $0
  pushl $161
  jmp idt_handler_common
.globl vector162
vector162:
  pushl $0
  pushl $162
  jmp idt_handler_common
.globl vector163
vector163:
  pushl $0
  pushl $163
  jmp idt_handler_common
.globl vector164
vector164:
  pushl $0
  pushl $164
  jmp idt_handler_common
.globl vector165
vector165:
  pushl $0
  pushl $165
  jmp idt_handler_common
.globl vector166
vector166:
  pushl $0
  pushl $166
  jmp idt_handler_common
.globl vector167
vector167:
  pushl $0
  pushl $167
  jmp idt_handler_common
.globl vector168
vector168:
  pushl $0
  pushl $168
  jmp idt_handler_common
.globl vector169
vector169:
  pushl $0
  pushl $169
  jmp idt_handler_common
.globl vector170
vector170:
  pushl $0
  pushl $170
  jmp idt_handler_common
.globl vector171
vector171:
  pushl $0
  pushl $171
  jmp idt_handler_common
.globl vector172
vector172:
  pushl $0
  pushl $172
  jmp idt_handler_common
.globl vector173
vector173:
  pushl $0
  pushl $173
  jmp idt_handler_common
.globl vector174
vector174:
  pushl $0
  pushl $174
  jmp idt_handler_common
.globl vector175
vector175:
  pushl $0
  pushl $175
  jmp idt_handler_common
.globl vector176
vector176:
  pushl $0
  pushl $176
  jmp idt_handler_common
.globl vector177
vector177:
  pushl $0
  pushl $177
  jmp idt_handler_common
.globl vector178
vector178:
  pushl $0
  pushl $178
  jmp idt_handler_common
.globl vector179
vector179:
  pushl $0
  pushl $179
  jmp idt_handler_common
.globl vector180
vector180:
  pushl $0
  pushl $180
  jmp idt_handler_common
.globl vector181
vector181:
  pushl $0
  pushl $181
  jmp idt_handler_common
.globl vector182
vector182:
  pushl $0
  pushl $182
  jmp idt_handler_common
.globl vector183
vector183:
  pushl $0
  pushl $183
  jmp idt_handler_common
.globl vector184
vector184:
  pushl $0
  pushl $184
  jmp idt_handler_common
.globl vector185
vector185:
  pushl $0
  pushl $185
  jmp idt_handler_common
.globl vector186
vector186:
  pushl $0
  pushl $186
  jmp idt_handler_common
.globl vector187
vector187:
  pushl $0
  pushl $187
  jmp idt_handler_common
.globl vector188
vector188:
  pushl $0
  pushl $188
  jmp idt_handler_common
.globl vector189
vector189:
  pushl $0
  pushl $189
  jmp idt_handler_common
.globl vector190
vector190:
  pushl $0
  pushl $190
  jmp idt_handler_common
.globl vector191
vector191:
  pushl $0
  pushl $191
  jmp idt_handler_common
.globl vector192
vector192:
  pushl $0
  pushl $192
  jmp idt_handler_common
.globl vector193
vector193:
  pushl $0
  pushl $193
  jmp idt_handler_common
.globl vector194
vector194:
  pushl $0
  pushl $194
  jmp idt_handler_common
.globl vector195
vector195:
  pushl $0
  pushl $195
  jmp idt_handler_common
.globl vector196
vector196:
  pushl $0
  pushl $196
  jmp idt_handler_common
.globl vector197
vector197:
  pushl $0
  pushl $197
  jmp idt_handler_common
.globl vector198
vector198:
  pushl $0
  pushl $198
  jmp idt_handler_common
.globl vector199
vector199:
  pushl $0
  pushl $199
  jmp idt_handler_common
.globl vector200
vector200:
  pushl $0
  pushl $200
  jmp idt_handler_common
.globl vector201
vector201:
  pushl $0
  pushl $201
  jmp idt_handler_common
.globl vector202
vector202:
  pushl $0
  pushl $202
  jmp idt_handler_common
.globl vector203
vector203:
  pushl $0
  pushl $203
  jmp idt_handler_common
.globl vector204
vector204:
  pushl $0
  pushl $204
  jmp idt_handler_common
.globl vector205
vector205:
  pushl $0
  pushl $205
  jmp idt_handler_common
.globl vector206
vector206:
  pushl $0
  pushl $206
  jmp idt_handler_common
.globl vector207
vector207:
  pushl $0
  pushl $207
  jmp idt_handler_common
.globl vector208
vector208:
  pushl $0
  pushl $208
  jmp idt_handler_common
.globl vector209
vector209:
  pushl $0
  pushl $209
  jmp idt_handler_common
.globl vector210
vector210:
  pushl $0
  pushl $210
  jmp idt_handler_common
.globl vector211
vector211:
  pushl $0
  pushl $211
  jmp idt_handler_common
.globl vector212
vector212:
  pushl $0
  pushl $212
  jmp idt_handler_common
.globl vector213
vector213:
  pushl $0
  pushl $213
  jmp idt_handler_common
.globl vector214
vector214:
  pushl $0
  pushl $214
  jmp idt_handler_common
.globl vector215
vector215:
  pushl $0
  pushl $215
  jmp idt_handler_common
.globl vector216
vector216:
  pushl $0
  pushl $216
  jmp idt_handler_common
.globl vector217
vector217:
  pushl $0
  pushl $217
  jmp idt_handler_common
.globl vector218
vector218:
  pushl $0
  pushl $218
  jmp idt_handler_common
.globl vector219
vector219:
  pushl $0
  pushl $219
  jmp idt_handler_common
.globl vector220
vector220:
  pushl $0
  pushl $220
  jmp idt_handler_common
.globl vector221
vector221:
  pushl $0
  pushl $221
  jmp idt_handler_common
.globl vector222
vector222:
  pushl $0
  pushl $222
  jmp idt_handler_common
.globl vector223
vector223:
  pushl $0
  pushl $223
  jmp idt_handler_common
.globl vector224
vector224:
  pushl $0
  pushl $224
  jmp idt_handler_common
.globl vector225
vector225:
  pushl $0
  pushl $225
  jmp idt_handler_common
.globl vector226
vector226:
  pushl $0
  pushl $226
  jmp idt_handler_common
.globl vector227
vector227:
  pushl $0
  pushl $227
  jmp idt_handler_common
.globl vector228
vector228:
  pushl $0
  pushl $228
  jmp idt_handler_common
.globl vector229
vector229:
  pushl $0
  pushl $229
  jmp idt_handler_common
.globl vector230
vector230:
  pushl $0
  pushl $230
  jmp idt_handler_common
.globl vector231
vector231:
  pushl $0
  pushl $231
  jmp idt_handler_common
.globl vector232
vector232:
  pushl $0
  pushl $232
  jmp idt_handler_common
.globl vector233
vector233:
  pushl $0
  pushl $233
  jmp idt_handler_common
.globl vector234
vector234:
  pushl $0
  pushl $234
  jmp idt_handler_common
.globl vector235
vector235:
  pushl $0
  pushl $235
  jmp idt_handler_common
.globl vector236
vector236:
  pushl $0
  pushl $236
  jmp idt_handler_common
.globl vector237
vector237:
  pushl $0
  pushl $237
  jmp idt_handler_common
.globl vector238
vector238:
  pushl $0
  pushl $238
  jmp idt_handler_common
.globl vector239
vector239:
  pushl $0
  pushl $239
  jmp idt_handler_common
.globl vector240
vector240:
  pushl $0
  pushl $240
  jmp idt_handler_common
.globl vector241
vector241:
  pushl $0
  pushl $241
  jmp idt_handler_common
.globl vector242
vector242:
  pushl $0
  pushl $242
  jmp idt_handler_common
.globl vector243
vector243:
  pushl $0
  pushl $243
  jmp idt_handler_common
.globl vector244
vector244:
  pushl $0
  pushl $244
  jmp idt_handler_common
.globl vector245
vector245:
  pushl $0
  pushl $245
  jmp idt_handler_common
.globl vector246
vector246:
  pushl $0
  pushl $246
  jmp idt_handler_common
.globl vector247
vector247:
  pushl $0
  pushl $247
  jmp idt_handler_common
.globl vector248
vector248:
  pushl $0
  pushl $248
  jmp idt_handler_common
.globl vector249
vector249:
  pushl $0
  pushl $249
  jmp idt_handler_common
.globl vector250
vector250:
  pushl $0
  pushl $250
  jmp idt_handler_common
.globl vector251
vector251:
  pushl $0
  pushl $251
  jmp idt_handler_common
.globl vector252
vector252:
  pushl $0
  pushl $252
  jmp idt_handler_common
.globl vector253
vector253:
  pushl $0
  pushl $253
  jmp idt_handler_common
.globl vector254
vector254:
  pushl $0
  pushl $254
  jmp idt_handler_common
.globl vector255
vector255:
  pushl $0
  pushl $255
  jmp idt_handler_common

# vector table
.globl __vectors
__vectors:
  .4byte vector0
  .4byte vector1
  .4byte vector2
  .4byte vector3
  .4byte vector4
  .4byte vector5
  .4byte vector6
  .4byte vector7
  .4byte vector8
  .4byte vector9
  .4byte vector10
  .4byte vector11
  .4byte vector12
  .4byte vector13
  .4byte vector14
  .4byte vector15
  .4byte vector16
  .4byte vector17
  .4byte vector18
  .4byte vector19
  .4byte vector20
  .4byte vector21
  .4byte vector22
  .4byte vector23
  .4byte vector24
  .4byte vector25
  .4byte vector26
  .4byte vector27
  .4byte vector28
  .4byte vector29
  .4byte vector30
  .4byte vector31
  .4byte vector32
  .4byte vector33
  .4byte vector34
  .4byte vector35
  .4byte vector36
  .4byte vector37
  .4byte vector38
  .4byte vector39
  .4byte vector40
  .4byte vector41
  .4byte vector42
  .4byte vector43
  .4byte vector44
  .4byte vector45
  .4byte vector46
  .4byte vector47
  .4byte vector48
  .4byte vector49
  .4byte vector50
  .4byte vector51
  .4byte vector52
  .4byte vector53
  .4byte vector54
  .4byte vector55
  .4byte vector56
  .4byte vector57
  .4byte vector58
  .4byte vector59
  .4byte vector60
  .4byte vector61
  .4byte vector62
  .4byte vector63
  .4byte vector64
  .4byte vector65
  .4byte vector66
  .4byte vector67
  .4byte vector68
  .4byte vector69
  .4byte vector70
  .4byte vector71
  .4byte vector72
  .4byte vector73
  .4byte vector74
  .4byte vector75
  .4byte vector76
  .4byte vector77
  .4byte vector78
  .4byte vector79
  .4byte vector80
  .4byte vector81
  .4byte vector82
  .4byte vector83
  .4byte vector84
  .4byte vector85
  .4byte vector86
  .4byte vector87
  .4byte vector88
  .4byte vector89
  .4byte vector90
  .4byte vector91
  .4byte vector92
  .4byte vector93
  .4byte vector94
  .4byte vector95
  .4byte vector96
  .4byte vector97
  .4byte vector98
  .4byte vector99
  .4byte vector100
  .4byte vector101
  .4byte vector102
  .4byte vector103
  .4byte vector104
  .4byte vector105
  .4byte vector106
  .4byte vector107
  .4byte vector108
  .4byte vector109
  .4byte vector110
  .4byte vector111
  .4byte vector112
  .4byte vector113
  .4byte vector114
  .4byte vector115
  .4byte vector116
  .4byte vector117
  .4byte vector118
  .4byte vector119
  .4byte vector120
  .4byte vector121
  .4byte vector122
  .4byte vector123
  .4byte vector124
  .4byte vector125
  .4byte vector126
  .4byte vector127
  .4byte vector128
  .4byte vector129
  .4byte vector130
  .4byte vector131
  .4byte vector132
  .4byte vector133
  .4byte vector134
  .4byte vector135
  .4byte vector136
  .4byte vector137
  .4byte vector138
  .4byte vector139
  .4byte vector140
  .4byte vector141
  .4byte vector142
  .4byte vector143
  .4byte vector144
  .4byte vector145
  .4byte vector146
  .4byte vector147
  .4byte vector148
  .4byte vector149
  .4byte vector150
  .4byte vector151
  .4byte vector152
  .4byte vector153
  .4byte vector154
  .4byte vector155
  .4byte vector156
  .4byte vector157
  .4byte vector158
  .4byte vector159
  .4byte vector160
  .4byte vector161
  .4byte vector162
  .4byte vector163
  .4byte vector164
  .4byte vector165
  .4byte vector166
  .4byte vector167
  .4byte vector168
  .4byte vector169
  .4byte vector170
  .4byte vector171
  .4byte vector172
  .4byte vector173
  .4byte vector174
  .4byte vector175
  .4byte vector176
  .4byte vector177
  .4byte vector178
  .4byte vector179
  .4byte vector180
  .4byte vector181
  .4byte vector182
  .4byte vector183
  .4byte vector184
  .4byte vector185
  .4byte vector186
  .4byte vector187
  .4byte vector188
  .4byte vector189
  .4byte vector190
  .4byte vector191
  .4byte vector192
  .4byte vector193
  .4byte vector194
  .4byte vector195
  .4byte vector196
  .4byte vector197
  .4byte vector198
  .4byte vector199
  .4byte vector200
  .4byte vector201
  .4byte vector202
  .4byte vector203
  .4byte vector204
  .4byte vector205
  .4byte vector206
  .4byte vector207
  .4byte vector208
  .4byte vector209
  .4byte vector210
  .4byte vector211
  .4byte vector212
  .4byte vector213
  .4byte vector214
  .4byte vector215
  .4byte vector216
  .4byte vector217
  .4byte vector218
  .4byte vector219
  .4byte vector220
  .4byte vector221
  .4byte vector222
  .4byte vector223
  .4byte vector224
  .4byte vector225
  .4byte vector226
  .4byte vector227
  .4byte vector228
  .4byte vector229
  .4byte vector230
  .4byte vector231
  .4byte vector232
  .4byte vector233
  .4byte vector234
  .4byte vector235
  .4byte vector236
  .4byte vector237
  .4byte vector238
  .4byte vector239
  .4byte vector240
  .4byte vector241
  .4byte vector242
  .4byte vector243
  .4byte vector244
  .4byte vector245
  .4byte vector246
  .4byte vector247
  .4byte vector248
  .4byte vector249
  .4byte vector250
  .4byte vector251
  .4byte vector252
  .4byte vector253
  .4byte vector254
  .4byte vector255

idt_handler_common:
pushal                    // Pushes edi,esi,ebp,esp,ebx,edx,ecx,eax

call irq_handler
popal

addl $8, %esp
sti
iret