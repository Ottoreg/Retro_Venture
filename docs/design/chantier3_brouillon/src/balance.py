"""Modèle d'équilibrage du chantier 3 (référence : joueur seul contre un groupe de 2 monstres de son niveau)."""
XP_ALPHA = 3.5  # multiplicateur d'XP de combat de l'alpha 1 (Character.XP_RATE dans le jeu)
def xp_step(n): return 60*n+20*n*n
def xp_total(n): return sum(xp_step(k) for k in range(1,n))
def pv_joueur(n): return 52+5*(n-1)+3+3*n          # Voie moyenne 52 PV, +5/niv, Vitalité race+équipement ~3/niv
def stat_joueur(n): return 5*(n-1)+5+3*n           # tout dans la carac principale + équipement ~3/niv
def dommages_joueur(n): return n//5
def degats_joueur(n): return 15*(1+stat_joueur(n)/100)+2*dommages_joueur(n)  # 15 de base par tour (6 PA)
def duree(n): return 2+n/10                         # tours du joueur pour vaincre 2 monstres
def pv_monstre(n): return round(14+3*n+0.06*n*n)
def stat_monstre(n): return 4*(n-1)
def degats_tour_monstre(n): return 0.4*pv_joueur(n)/(1.5*duree(n))/0.7  # 40 % des PV du joueur par combat de référence, 70 % des coups portent
def degats_sort(n): return degats_tour_monstre(n)/1.6
def xp_monstre(n): return round(7*n+0.27*n*n)
def ecus(n):
    a=2+1.2*n; return [max(1,round(a*0.6)),round(a*1.4)]
def minutes_niveau(n): return 5.5+1.56*n
def minutes_combat(n): return 1+0.04*n
def budget_objet(L, rarete):
    m={'commun':1,'peu_commun':1.2,'rare':1.45,'epique':1.8,'legendaire':2.2}[rarete]
    return round((3+0.8*L)*m,1)
monstres=[]; joueurs=[]
for n in range(1,31):
    dm=degats_sort(n); s=stat_monstre(n)
    monstres.append({"niveau":n,"pv":pv_monstre(n),"degats_moyens_par_sort":round(dm,1),"base_sort_conseillee":round(dm/(1+s/100),1),
        "stat_element":s,"par_niveau_pv":round(3+0.12*n),"xp":xp_monstre(n),"ecus":ecus(n)})
    joueurs.append({"niveau":n,"xp_total":xp_total(n),"xp_pour_suivant":xp_step(n) if n<30 else 0,"pv":pv_joueur(n),"carac_principale":stat_joueur(n),
        "dommages":dommages_joueur(n),"degats_par_tour":round(degats_joueur(n),1),"tours_contre_2_monstres":round(duree(n),1),
        "minutes_pour_ce_niveau":round(minutes_niveau(n),1) if n<30 else 0,"combats_pour_ce_niveau":round(minutes_niveau(n)/minutes_combat(n)) if n<30 else 0})
if __name__=='__main__':
    for m,j in zip(monstres,joueurs): print(m); print('   ',j)
    print(sum(minutes_niveau(n) for n in range(1,30))/60, sum(minutes_niveau(n) for n in range(1,12))/60, sum(minutes_niveau(n) for n in range(1,10))/60)
    print('combats 1-12',sum(minutes_niveau(n)/minutes_combat(n) for n in range(1,12)),'12-30',sum(minutes_niveau(n)/minutes_combat(n) for n in range(12,30)))
    for L in [1,3,5,8,10,12,15,18,20,24,28,30]: print(L,budget_objet(L,'commun'),budget_objet(L,'rare'),budget_objet(L,'epique'))
