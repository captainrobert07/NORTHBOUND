from pathlib import Path
import re, json, html
p=Path('/mnt/data/northbound-smart-2027');base=Path('/mnt/data/North_India_Trip_Interactive.html').read_text()
# insert CSS into single-file deployable HTML
style=(p/'enhancements.css').read_text()
base=base.replace('</style>', '\n'+style+'\n</style>',1)
# navigation expands
needle='<button data-view="essentials">Essentials</button>'
addition=needle+'<button data-view="studio">Trip Studio</button><button data-view="connections">Live Connections</button><button data-view="bookings">Bookings</button><button data-view="groupcloud">Shared Group</button><button data-view="coach">Trip Coach</button><button data-view="journal">Journal & Offline</button>'
assert needle in base;base=base.replace(needle,addition,1)
# add custom views
assert '</main>' in base;base=base.replace('</main>',(p/'new_views.html').read_text()+'\n</main>',1)
# expense screen independent edit and file attach
rec='''<div class="v2-grid two" style="margin-top:16px"><div class="v2-card"><h3>Attach an expense receipt</h3><p class="v2-muted">Receipts are stored privately in this device's IndexedDB. Uploads are never automatic.</p><div class="v2-form"><div class="v2-field wide"><label>Expense</label><select id="v2-receipt-expense"></select></div><div class="v2-field wide"><label>Receipt PDF or photo (max 5 MB)</label><input id="v2-receipt-file" type="file" accept="application/pdf,image/png,image/jpeg,image/webp"></div><div class="v2-row wide"><button class="btn small primary" id="v2-receipt-save">Save receipt</button><button class="btn small" id="v2-receipt-open">Open receipt</button></div></div></div><div class="v2-card"><h3>Correct an expense</h3><div class="v2-form"><div class="v2-field wide"><label>Expense</label><select id="v2-edit-expense"></select></div><button class="btn small wide" id="v2-edit-expense-btn">Load expense for editing</button><div class="v2-field"><label>Correct amount (₹)</label><input id="v2-exp-edit-value" type="number" step="0.01" min="0.01"></div><div class="v2-field"><label>Correct description</label><input id="v2-exp-edit-desc" maxlength="160"></div><button class="btn primary wide" id="v2-edit-expense-save">Save correction & recalculate splits</button></div><p class="v2-tiny">Custom shares are proportionally adjusted when the total changes; review the result in Split Bills.</p></div></div>'''
# insert just before closing of expenses section
ix=base.index('<section id="splitter"');close=base.rfind('</section>',0,ix);assert close!=-1;base=base[:close]+rec+'\n'+base[close:]
# pre-hydrate saved route before original initializer
needle='<script>\n(function(){\'use strict\';'
assert needle in base
hydrate='''<script>\n// Restore a saved route before the original planner/map is initialized.\ntry{const saved=JSON.parse(localStorage.getItem('northbound_v2_destinations')||'null');if(Array.isArray(saved)&&saved.length>1&&saved.length<150&&saved.every(x=>x&&typeof x.name==='string'&&Number.isFinite(Number(x.lat))&&Number.isFinite(Number(x.lng))))DATA.stops.splice(0,DATA.stops.length,...saved)}catch{}\n</script>\n'''
base=base.replace(needle,hydrate+needle,1)
# broadcast core updates to cloud
pattern=r"function store\(k,v\)\{try\{localStorage\.setItem\(K\+k,JSON\.stringify\(v\)\)\}catch\(e\)\{toast\('Storage unavailable: use a regular browser tab\.'\)\}\}"
replacement="function store(k,v){try{localStorage.setItem(K+k,JSON.stringify(v));window.dispatchEvent(new CustomEvent('nb:update',{detail:{key:k,value:v}}))}catch(e){toast('Storage unavailable: use a regular browser tab.')}}"
base,count=re.subn(pattern,replacement,base,1);assert count==1,count
# repayments apply to rendered settlements
needle="for(const n in bal)bal[n]=money(bal[n]);"
repay="""try{const repay=JSON.parse(localStorage.getItem('northbound_v2_payments')||'[]');if(Array.isArray(repay))for(const r of repay){const amount=Number(r.amount)||0;if(amount>0&&r.from in bal&&r.to in bal){bal[r.from]+=amount;bal[r.to]-=amount}}}catch{}for(const n in bal)bal[n]=money(bal[n]);"""
assert needle in base;base=base.replace(needle,repay,1)
# expose safe bridge for group synchronization
needle='init();\n})();\n</script>'
if needle not in base:needle='init(); })();\n</script>'
assert needle in base
bridge="""window.NB={
 get:()=>({members:JSON.parse(JSON.stringify(members)),expenses:JSON.parse(JSON.stringify(expenses)),budgets:JSON.parse(JSON.stringify(budgets)),checks:JSON.parse(JSON.stringify(checks)),returnVariant}),
 importRemote:data=>{if(Array.isArray(data.members)&&data.members.length&&data.members.length<=60)members=data.members; if(Array.isArray(data.expenses)&&data.expenses.length<20000)expenses=data.expenses; if(data.budgets&&typeof data.budgets==='object')budgets=data.budgets; if(data.checks&&typeof data.checks==='object')checks=data.checks;if(['direct','mumbai'].includes(data.returnVariant))returnVariant=data.returnVariant;
 for(const [k,v] of Object.entries({members,expenses,budgets,checks,return:returnVariant}))localStorage.setItem(K+k,JSON.stringify(v));renderCatSelect();renderMemberControls();renderExpenses();renderSplit();renderChecklist();updateReturn();},
 renderSplit:()=>renderSplit(),refresh:()=>{renderMemberControls();renderExpenses();renderSplit();renderChecklist();renderStops()}
};
"""
base=base.replace(needle,bridge+needle,1)
# append enhanced classic script and cloud module
inject='\n<script>\n'+(p/'enhancements.js').read_text()+'\n</script>\n<script type="module">\n'+(p/'cloud.js').read_text()+'\n</script>\n'
assert '</body>' in base;base=base.replace('</body>',inject+'</body>',1)
# PWA metadata and preload
base=base.replace('</head>','''<link rel="manifest" href="/manifest.webmanifest"><link rel="icon" href="/assets/icon-192.png" type="image/png"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-title" content="NORTHBOUND"><meta name="color-scheme" content="dark">\n</head>''',1)
# improve original misleading claim about image or GPS
base=base.replace('illustrative group budget','per-person example budget')
base=base.replace('No location coordinates are stored or uploaded by this app.', 'GPS coordinates are not saved or shared with the group. If you request live road directions, coordinates are sent to the routing service.')
# update footer copy
base=base.replace('Money stays in your browser', 'Local by default · optional Supabase group sync')
(p/'index.html').write_text(base)
Path('/mnt/data/North_India_Trip_Smart_App.html').write_text(base)
print('Wrote index',len(base),'bytes; embedded route, GPS, cloud, spending and custom planning.');
