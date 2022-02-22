/*--------------------------------------------------------------------------------------------------------
* Copyright (c) Sagene Corporation. All rights reserved.
* Licensed under the CC BY-NC-ND 4.0 License. See License.txt in the project root for license information.
* ------------------------------------------------------------------------------------------------------*/

    
// Params
// 参数配置
    
// 图片库
const pics = {
  "盖章": "https://sagene-i-cloud.s3.cn-north-1.amazonaws.com.cn/data/private/report_template/default/%E8%B3%BD%E5%93%B2/stamp.png",
  "蒙版": "https://sagene-i-cloud.s3.cn-north-1.amazonaws.com.cn/data/public/report_template/%E8%B5%9B%E5%93%B2/transparent.png"
}

  
// 字体库
const fonts = {
  "思源黑体": ["source_han_sans",
      "https://sagene-i-cloud.s3.cn-north-1.amazonaws.com.cn/data/private/report_template/fonts/SourceHanSans.ttf"],
  "思源黑体加粗": ["source_han_sans_bold", 
      "https://sagene-i-cloud.s3.cn-north-1.amazonaws.com.cn/data/private/report_template/fonts/SourceHanSans-Bold.ttf"],
  "times_new_roman_italic": ["times_new_roman_italic",
      "https://sagene-i-cloud.s3.cn-north-1.amazonaws.com.cn/data/private/report_template/fonts/Times+New+Roman+Italic.ttf"]
}

// 文档库
// 阳性判断值
const cutoff = {
  "鲍氏不动杆菌": 11,
  "肺炎链球菌": 11,
  "大肠埃希菌": 33,
  "肺炎克雷伯菌": 10,
  "金黄色葡萄球菌": 6,
  "流感嗜血杆菌": 21,
  "新型隐球菌": 11,
  "格特隐球菌": 14,
  "人巨细胞病毒": 4,
  "人类疱疹病毒1": 5,
  "单纯疱疹病毒": 5,
  "EB病毒": 7
}

// 动态信息
const sample_info = report['sample_info']
const report_stats = report['report_stats']
const report_results = report['report_results']
const background_results = report['report_bg_bacterias'] || []
const gene_results = report['selected_rg_reports'] || []
const reviewed_results = report['reviewed_results'] || {}
const library_type = report['library_type']
const reads_quality = report['reads_qualify']
const q30_quality = report['q30_qualify']

const Infos = {
  "患者姓名": sample_info['patient_name'] || '-',
  "送检单位": sample_info["inspection_company"] || '-',
  "送检样本": sample_info["sample_type"] || '-',
  "送检编号": sample_info["sample_name"] || '-',
  "检测项目": sample_info["project"] || '-',
  "报告编号": sample_info["serial_number"] || '-',
  "报告日期": sample_info["submit_time"],
  "性别": sample_info["patient_gender"] || '-',
  "年龄": sample_info["patient_age"] || '-',
  "住院号": sample_info["hospital_number"] || "-",
  "床号": sample_info["bed_number"] || "-",
  "联系方式": sample_info["patient_phone"] || '-',
  "样本来源": sample_info["inspection_department"] || '-',
  "送检医生": sample_info["inspection_doctor"] || '-',
  "采样时间": sample_info["sampling_time"] || '-',
  "收样时间": sample_info["collection_time"] || '-',
  "临床诊断": sample_info["clinical_diagnosis"] || '-'
}
const QC = {
  "总序列数": reads_quality,
  "测序质量": q30_quality,
  "阴性参考品检出": "是",
  "阴性参考品": reviewed_results["negative_judgment"] || "合格",
  "阳性参考品检出": "是",
  "阳性参考品": reviewed_results["positive_judgment"] || "合格",
}

// 静态文本
const words = {
  "页眉": "报告编号：" + Infos["报告编号"],
  "页脚": "本报告仅供专业的研究人员及临床医生参考，不作为临床确诊的唯一依据。"
}

// 表格标题
const pathogens = ["类型", "属", "种", "检出序列数", "判断值", "结果"]

// 注释信息
const AnnotationQC = [
  ["数据量", "下机序列reads总数，合格标准为不少于10.0M。"],
  ["测序质量（Q30）", "表示质量值≥30的碱基数（百分比）。质量值为30，则错误识别的概率是0.1%，即正确率是99.9%。合格标准为不低于75.0%。"],
  ["室内质控品", "室内质控品的检测结果应为阴性，若其中有其他微生物物种检出，说明提取过程可能存在异常。"],
  ["阴性对照参考", "阴性质控品的检测结果应为阴性，若其中有其他微生物物种检出，说明环境中可能存在微生物核酸污染源。"],
  ["阳性对照参考", "阳性质控品的检测结果应为肺炎克雷伯菌、金黄色葡萄球菌、格特隐球菌、EB病毒对应阳性；如果未检出，说明试剂盒性能不理想或操作过程有误，此次检测结果无效。"],
]
const AnnotationTables = [
  ["类型", "“B”表示细菌；“B:G+”表示革兰阳性细菌；“B:G-”表示革兰阴性细菌；“P”表示支原体、衣原体或嗜衣原体；“F”表示真菌；“V”表示病毒；“I”表示其他。"],
  ["属", "该物种双名法中属名的中文译名，若未翻译则用其拉丁名表示。"],
  ["种", "该物种/亚种双名法（或三名法）命名的中文译名及其拉丁名，若未翻译则用“-”表示。"],
  ["检出序列数", "指比对上该微生物序列的片段数。"],
  ["判断值", "该物种检测为阳性的参考值。"],
  ["结果", "该物种本次检测结果，\"+\"表示阳性，\"-\"表示阴性。"]
]
const Declares = [
  "本报告检测结果仅对本次送检样品负责。",
  "鉴于目前医学中分子检测技术的局限性，以上检测结果仅供临床参考，如对检测结果持有异议，请于收到本报告起7个工作日内与我们取得联系；",
  "本检测报告涂改无效，内容缺损无效；",
  "本公司对以上检测结果保留最终解释权。"
]

// View
// 视图结构
const RPDseq = () => (
  // PDF所有页面为一个整体
  <Document>
      {/* 正文，文档核心部分，由不同章节构成 */}
      <Page title="正文" style={ styles.layout }>
          {/* 页眉页码 */}
          <Header style={{ textAlign: "center" }} fixed>{ project }</Header>
          <Header fixed>{ words["页眉"] }</Header>
          <Pagination render={( {pageNumber, totalPages} ) => `${pageNumber}`} fixed></Pagination>

          {/* 章节一，概述 */}
          <Section title="基本信息">
              <Headline1>基本信息</Headline1>

              {/* 基本信息 */}
              <TableHeader>受检信息</TableHeader>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["姓名", Infos["患者姓名"], "性别", Infos["性别"]]}
                  weight={[0.2, 0.3, 0.2, 0.3]} 
                  backgroundColor={["#ecf8f8", "", "#ecf8f8", ""]}
              ></CustomTable>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["年龄", Infos["年龄"], "联系方式", Infos["联系方式"]]}
                  weight={[0.2, 0.3, 0.2, 0.3]} 
                  backgroundColor={["#ecf8f8", "", "#ecf8f8", ""]}
              ></CustomTable>

              <TableHeader>样本信息</TableHeader>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["送检医院", Infos["送检单位"]]}
                  weight={[0.2, 0.8]} 
                  backgroundColor={["#ecf8f8", ""]}
              ></CustomTable>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["送检科室", Infos["样本来源"], "送检医生", Infos["送检医生"]]}
                  weight={[0.2, 0.3, 0.2, 0.3]} 
                  backgroundColor={["#ecf8f8", "", "#ecf8f8", ""]}
              ></CustomTable>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["送检编号", Infos["送检编号"], "样本类型", Infos["送检样本"]]}
                  weight={[0.2, 0.3, 0.2, 0.3]} 
                  backgroundColor={["#ecf8f8", "", "#ecf8f8", ""]}
              ></CustomTable>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["报告编号", Infos["报告编号"], "报告时间", Infos["报告日期"]]}
                  weight={[0.2, 0.3, 0.2, 0.3]} 
                  backgroundColor={["#ecf8f8", "", "#ecf8f8", ""]}
              ></CustomTable>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["检测项目", Infos["检测项目"], "收样时间", Infos["收样时间"]]}
                  weight={[0.2, 0.3, 0.2, 0.3]} 
                  backgroundColor={["#ecf8f8", "", "#ecf8f8", ""]}
              ></CustomTable>

              <TableHeader>质检信息</TableHeader>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["质控项", "质检情况", "质控结果"]}
                  weight={[0.2, 0.4, 0.4]} 
                  backgroundColor="#ecf8f8"
              ></CustomTable>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["数据量", report_stats["QC"]["Total_number_of_raw_reads"], QC["总序列数"]]}
                  weight={[0.2, 0.4, 0.4]} 
                  backgroundColor={["#ecf8f8", "", ""]}
              ></CustomTable>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["数据量", report_stats["QC"]["q30"], QC["测序质量"]]}
                  weight={[0.2, 0.4, 0.4]} 
                  backgroundColor={["#ecf8f8", "", ""]}
              ></CustomTable>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["室内质控品", "合格"]}
                  weight={[0.2, 0.8]} 
                  backgroundColor={["#ecf8f8", ""]}
              ></CustomTable>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["阴性对照参考", QC["阴性参考品"]]}
                  weight={[0.2, 0.8]} 
                  backgroundColor={["#ecf8f8", ""]}
              ></CustomTable>
              <CustomTable
                  style={{ paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px", textAlign: "center" }} 
                  data={["阳性对照参考", QC["阳性参考品"]]}
                  weight={[0.2, 0.8]} 
                  backgroundColor={["#ecf8f8", ""]}
              ></CustomTable>

              <Annotation>
                  <Text style={{ marginTop: "100px" }}>说明：</Text>
                  { AnnotationQC.map(( items, index ) => (
                      <Text key={index}>
                          <Text style={{ fontFamily: "source_han_sans_bold" }}>{items[0] + "："}</Text>
                          <Text>{items[1]}</Text>
                      </Text>
                    ))
                  }
              </Annotation>
          </Section>

          {/* 章节二，病原体列表 */}
          <Section title="物种表格汇总" break>
              <Headline1>检测结果</Headline1>
              {/* 不同类型的物种表 */}
              {
                  speciesTables.map(( item, index ) => (
                      <View key={index}>
                          <Headline2>表1-{index + 1} {item[0]}</Headline2>
                          <SpeciesTable species={item[1]} annotation={item[2]}></SpeciesTable>
                      </View>
                  ))
              }

              {/* 物种表注释 */}
              <Annotation>
                  <Text>注释：</Text>
                  { AnnotationTables.map(( items, index ) => (
                      <Text key={index}>
                          <Text style={{ fontFamily: "source_han_sans_bold" }}>{items[0] + "："}</Text>
                          <Text>{items[1]}</Text>
                      </Text>
                    ))
                  }
              </Annotation>
          </Section>

          {/* 章节三，解释与免责 */}
          <Section title="结果解释及检测声明" break>
              <Headline1 style={{ marginBottom: "17px" }}>结果解释及检测声明</Headline1>
              <Headline2>检测声明</Headline2>
              { Declares.map( (items, index) => (
                  <View key={index} style={ {display: "flex", flexDirection: "row", paddingLeft: "15px", lineHeight: "3pt"} }>
                      <Text style={{ paddingRight: "3px", fontFamily: "source_han_sans_bold" }}>{(index+1)+"."}</Text>
                      <Text style={{ fontFamily: "source_han_sans" }}>{items}</Text>
                  </View>
              )) }
              <View style={{ position: "relative", marginTop: "200px", width: "500px", height: "50px", display: "flex", flexDirection: "row", justifyContent: "space-around"}}>
                  <View style={{ width: "180px", height: "50px", fontFamily: "source_han_sans" }}>
                      <Text style={{ position: "absolute", bottom: "0px" }}>报告审核人：</Text>
                  </View>
                  <View style={{ width: "180px", height: "50px", fontFamily: "source_han_sans" }}>
                      <Image allowDangerousPaths={true} style={{ height: "60px", width: "100px", left: "-10px" }}  src={ pics["盖章"] }></Image>
                      <Text style={{ position: "absolute", bottom: "0px" }}>报告日期：{ new Date(Infos["报告日期"].replace(/-/g, "/")).toLocaleDateString() }</Text>
                  </View>
              </View>
          </Section>

          {/* 正文页脚，含页码 */}
          <Footer fixed>{ words["页脚"] }</Footer>
          
          {/* 蒙版图，防止底部图片被选中 */}
          <View style={{ position: "absolute" }} fixed>
              <Image allowDangerousPaths={true} style={{ height: "700px", width: "1000px" }} src={ pics["蒙版"] }></Image>
          </View>
      </Page>
  </Document>
)


// component
// 可重用组件

/**
*  自定义表格组件，用于表格中一行的渲染，文档内所有表格的基础
*
*  @prop data 每一行的数据列表，当数据项为字符串时直接渲染，为子数组时将数组拆分以不同策略渲染（用于物种中英文名单元格）
*  @prop weight 单元格的权重列表，即宽度占比，列表中权重总和为1
*  @prop border 边框属性，默认值为1pt solid #14938C
*  @prop backgroundColor 单元格背景颜色，如果值为字符串则被整行采用，如果值为列表，则不同单元格分别上色，缺省值为白色
*  @prop hasTop 是否渲染上部边框，一般单元格的标题行应该渲染，非标题行不用渲染
*  @prop style 用于单元格的额外样式
*/
const CustomTable = (props) => {
  const data = Object.prototype.toString.call(props.data) === "[object String]" ? [props.data] : props.data
  const length = data.length;
  const weight = props.weight || new Array(length).fill(1 / length)
  const border = props.border || "1.1pt solid #14938C";
  const backgroundColor = Object.prototype.toString.call(props.backgroundColor) === "[object String]" ?
      new Array(length).fill(props.backgroundColor) :
      props.backgroundColor ||  new Array(length).fill("")
  const hasTop = props.hasTop;
  const borderTop = hasTop ? border : "0"
  const style = props.style

  // 前n-1个单元格
  const items = data.slice(0, -1).map((item, index) => (
          Object.prototype.toString.call(item) === "[object String]" ? (
              <View wrap={false} key={index} style={[
                  {width: weight[index] * 100 + "%", fontFamily: "source_han_sans", borderRight: `${border}`, backgroundColor: `${backgroundColor[index]}`},
                  style
              ]}>
                  <Text>{item}</Text>
              </View>
          ) : (
              <SpeciesName warp={false} key={index} style={[
                  {width: weight[index] * 100 + "%", borderRight: `${border}`}
              ]}>
                  <Text style={{ marginBottom: "8px" }}>{item[0]}</Text>
                  <Text style={{ fontFamily: "times_new_roman_italic" }}>{item[1]}</Text>
              </SpeciesName>
          )
      )
  )

  // 最后一个单元格
  const lastOne = <View wrap={false} style={[
      {width: weight.slice(-1) * 100 + "%", fontFamily: "source_han_sans", backgroundColor: `${backgroundColor.slice(-1)}`},
      style
  ]}>
      <Text>{data.slice(-1)}</Text>
  </View>

  // 一行表格的视图
  return (
      <View wrap={false} style={[
          { width: "500px",  border: `${border}`, display: "flex", flexDirection: "row", justifyContent: "space-around" },
          { borderTop: `${borderTop}` }
      ]}>
          {items}
          {lastOne}
      </View>
  )
}

/**
* 物种表标题行组件
*/
const SpeciesTableHead = () => (
  <CustomTable
      style={{ textAlign: "center", paddingTop: "10px", paddingBottom: "6px", fontFamily: "source_han_sans_bold" }} data={ pathogens }
      weight={[0.15, 0.2, 0.35, 0.1, 0.1, 0.1]} hasTop={true}
      backgroundColor="#CCEBED"
  ></CustomTable>
)

/**
* 物种表（行）组件
*
* @props species 病原体结果列表
*/
const SpeciesTable = (props) => {
  const species = props.species
  const annotation = props.annotation
  // 病原体结果为空时渲染为“未发现”
  if (species.length !== 0) {
      return (
          <View>
              <SpeciesTableHead />
              {species.map((items, index) => (
                  <CustomTable
                      key={index} style={{ display: "flex", flexDirection: "row", alignItems: "center", textAlign: "center", paddingTop: "10px", paddingBottom: "6px", paddingLeft: "5px" }} data={items}
                      weight={[0.15, 0.2, 0.35, 0.1, 0.1, 0.1]}
                  ></CustomTable>))}
          </View>
      )
  } else {
      return (
          <View wrap={false}>
              <SpeciesTableHead />
              <CustomTable style={{ textAlign: "center", paddingTop: "10px", paddingBottom: "6px" }} data={[annotation]}></CustomTable>
          </View>
      )
  }
}


// Data
/**
* 报告物种对应关系及再处理
*/
// 获取输出列
function get_cols(item, type) {
  let coL_names = ["Type", "C_name_g", "C_name_s", "L_name", "uRPTM", "Intro"]
  let new_item = {}
  for (let key in item) {
      if (coL_names.includes(key)) {
          new_item[key] = item[key]
      }
  }
  new_item['class'] = type
  return new_item
}

// 报告物种获取
const SpeciesFrom = {
  "细菌": report_results.filter((item) => (item['Type'].indexOf("B") == 0 && item['C_name_g'] != "分枝杆菌属")).map(item => get_cols(item, "细菌")),
  "分枝杆菌": report_results.filter((item) => (item['C_name_g'] == "分枝杆菌属")).map(item => get_cols(item, "分枝杆菌")),
  "支衣原体": report_results.filter((item) => (item['Type'].indexOf("P") == 0)).map(item => get_cols(item, "支衣原体")),
  "真菌": report_results.filter((item) => (item['Type'].indexOf("F") == 0)).map(item => get_cols(item, "真菌")),
  "DNA病毒": report_results.filter((item) => (item['Type'].indexOf("V:D") == 0)).map(item => get_cols(item, "DNA病毒")),
  "RNA病毒": report_results.filter((item) => (item['Type'].indexOf("V") == 0 && item['Type'].indexOf("V:D") == -1)).map(item => get_cols(item, "RNA病毒")),
  "其他病原微生物": report_results.filter((item) => (item['Type'].indexOf("I") == 0)).map(item => get_cols(item, "其他病原微生物")),
}

// 重新计算占比
function count_rate(items, type) {
  let reads = 0
  var item
  for (item of items) {
      reads += parseInt(item["uRPTM"])
  }
  let new_items = []
  for (item of items) {
      item['reads_percent'] = (item['uRPTM'] / reads * 100).toFixed(2) + '%'
      if (item['class'] === type ) {
          new_items.push(item)
      }
  }
  new_items.sort((a, b) => (parseInt(b['uRPTM']) - parseInt(a['uRPTM'])))
  return new_items
}

// 报告物种中间处理
const SpeciesWith = {
  "细菌": count_rate(SpeciesFrom["细菌"].concat(SpeciesFrom['分枝杆菌']), "细菌"),
  "分枝杆菌": count_rate(SpeciesFrom["分枝杆菌"].concat(SpeciesFrom['细菌']), "分枝杆菌"),
  "支衣原体": count_rate(SpeciesFrom["支衣原体"], "支衣原体"),
  "真菌": count_rate(SpeciesFrom["真菌"], "真菌"),
  "DNA病毒": count_rate(SpeciesFrom["DNA病毒"], "DNA病毒"),
  "RNA病毒": count_rate(SpeciesFrom["RNA病毒"], "RNA病毒"),
  "其他病原微生物": count_rate(SpeciesFrom["其他病原微生物"], "其他病原微生物"),
}

// 报告物种转数组
function to_array(items) {
  var new_items = []
  for (let item of items) {
      tmp = []
      threshold = cutoff[item['C_name_s']]
      if (typeof threshold === "undefined") {
          continue
      }
      character = parseInt(item['uRPTM']) >= threshold ? "+" : "-"
      tmp.push(item['Type'], item['C_name_g'], [item['C_name_s'], item['L_name']], String(parseInt(item['uRPTM'])), "≥"+threshold, character)
      new_items.push(tmp)
  }
  return new_items
}

// 获取百科
function get_wiki(items) {
  let bool = false
  let new_items = []
  for (let key in items) {
      for (let item of items[key]) {
          bool = true
          if (item['Intro'] !== "-") {
              if (item['C_name_s'] !== "-") {
                  new_items.push([item['C_name_s'], item['Intro']])
              } else {
                  new_items.push([item['L_name'], item['Intro']])
              }
          }
      }
  }
  return bool ? new_items : undefined
}

// 用于渲染的报告物种数据
const SpeciesTo = {
  "细菌": to_array(SpeciesWith["细菌"]),
  "分枝杆菌": to_array(SpeciesWith["分枝杆菌"]),
  "支衣原体": to_array(SpeciesWith["支衣原体"]),
  "真菌": to_array(SpeciesWith["真菌"]),
  "DNA病毒": to_array(SpeciesWith["DNA病毒"]),
  "RNA病毒": to_array(SpeciesWith["RNA病毒"]),
  "其他病原微生物": to_array(SpeciesWith["其他病原微生物"]),
  "物种百科": get_wiki(SpeciesWith)
}

/**
* 物种表分表逻辑
*/
const project = Infos['检测项目']
const template = library_type

const Bacteria = SpeciesTo["细菌"]
const Mycobacterium = SpeciesTo["分枝杆菌"]
const ChlamydiaAndMycoplasma = SpeciesTo["支衣原体"]
const Fungi = SpeciesTo["真菌"]
const DNAVirus = SpeciesTo["DNA病毒"]
const RNAVirus = SpeciesTo["RNA病毒"]
const Parasites = SpeciesTo["其他病原微生物"]

var speciesTables = [[]]
if (project.indexOf("DNA") != -1 && project.indexOf("RNA") != -1) {
  speciesTables = [
      ["细菌", Bacteria, template == "RNA" ? "见该样本DNA检测报告" : "未发现"],
      ["分枝杆菌", Mycobacterium, template == "RNA" ? "见该样本DNA检测报告" : "未发现"],
      ["支原体/衣原体", ChlamydiaAndMycoplasma, template == "RNA" ? "见该样本DNA检测报告" : "未发现"],
      ["真菌", Fungi, template == "RNA" ? "见该样本DNA检测报告" : "未发现"],
      ["DNA病毒", DNAVirus, template == "RNA" ? "见该样本DNA检测报告" : "未发现"],
      ["RNA病毒", RNAVirus, template == "DNA" ? "见该样本RNA检测报告" : "未发现"],
      ["其他病原微生物", Parasites, template == "RNA" ? "见该样本DNA检测报告" : "未发现"]
  ]
} else if (project.indexOf("DNA") != -1) {
  speciesTables = [
      ["细菌", Bacteria, "未发现"],
      ["分枝杆菌", Mycobacterium, "未发现"],
      ["支原体/衣原体", ChlamydiaAndMycoplasma, "未发现"],
      ["真菌", Fungi, "未发现"],
      ["DNA病毒", DNAVirus, "未发现"],
      ["其他病原微生物", Parasites, "未发现"]
  ]
} else if (project.indexOf("RNA") != -1) {
  speciesTables = [
      ["RNA病毒", RNAVirus, "未发现"]
  ]
}
console.log(speciesTables[0][1])
// Style
// 文档样式，布局与细节调整

// 字体载入
Object.keys(fonts).forEach(item => Font.register({ family: fonts[item][0], src: fonts[item][1] }))

// 中文断字
Font.registerHyphenationCallback(
  word => word.length === 1 ? [word] : Array.from(word).map(
      (char) => [char, '']).reduce((arr, current) => {arr.push(...current); return arr}, []
  )
)

// 样式组件，使用此类组件会渲染对应样式
// 框架
const Body = styled.View`
position: absolute;
padding-top: 85px;
padding-bottom: 60px;
padding-left: 50px;
padding-right: 50px;
font-size: 9px;
font-family: source_han_sans;
`

// 章节
const Section = styled.View`
`

// 一号标题
const Headline1 = styled.Text`
margin-top: 15px;
color: #14938C;
font-size: 20px;
font-family: source_han_sans;
`

// 二号标题
const Headline2 = styled.Text`
margin-top: 30px;
margin-bottom: 8px;
font-size: 16px;
text-align: center;
`

// 表格标题
const TableHeader = styled.Text`
width: 500px;
margin-top: 10px;
padding-bottom: 5px;
border-bottom: 1pt solid #14938C;
text-align: center;
font-family: source_han_sans;
font-size: 16px;
`

// 物种中英文混合父元素
const SpeciesName = styled.View`
display: flex;
flex-direation: column;
justify-content: space-around;
align-items: center;
padding-top: 10px;
padding-bottom: 6px;
`

// 注释信息
const Annotation = styled.View`
margin-top: 30px;
line-height: 3pt;
`

// 页眉
const Header = styled.Text`
position: absolute;
top: 20px;
left: 50px;
width: 500px;
height: 30px;
border-bottom-width: 1px;
border-style: solid;
border-color: #C3E6E8;
padding-top: 10.5px;
font-family: source_han_sans;
font-size: 9px;
text-align: right;
`

// 页脚
const Footer = styled.Text`
position: absolute;
bottom: 35px;
left: 50px;
width: 500px;
height: 15px;
text-align: center;
font-family: source_han_sans;
font-size: 9px;
`

// 页码
const Pagination = styled.Text`
position: absolute;
top: 20px;
left: 50px;
width: 30px;
height: 30px;
border-right-width: 30px;
borderStyle: solid;
borderColor: #C3E6E8;
padding-top: 10px;
text-align: center;
font-size: 9px;
`

// 样式表，CSS部分参考https://www.w3school.com.cn/cssref/index.asp
const styles = StyleSheet.create({
  layout: {
      position: "absolute",
      paddingTop: 85,
      paddingBottom: 60,
      paddingHorizontal: 50,
      fontSize: 9,
      fontFamily: "source_han_sans",
  }
})

// 启动渲染
ReactPDF.render(<RPDseq />)
