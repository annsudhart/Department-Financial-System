from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('connect', views.connect, name='connect'),
    path('normalize', views.normalize, name='normalize')
]