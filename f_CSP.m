function [result] = f_CSP(varargin)
    if (nargin ~= 2)
        disp('Must have 2 classes for CSP!')
    end
    Rsum=0;
    for i = 1:nargin 
        R{i} = ((varargin{i}*varargin{i}')/trace(varargin{i}*varargin{i}'));%instantiate me before the loop!
        Rsum=Rsum+R{i};
    end
    [EVecsum,EValsum] = eig(Rsum);
    [EValsum,ind] = sort(diag(EValsum),'descend');
    EVecsum = EVecsum(:,ind);
      
    W = sqrt(inv(diag(EValsum))) * EVecsum';
    for k = 1:nargin
        S{k} = W * R{k} * W'; %       Whiten Data Using Whiting Transform - Ramoser Equation (4)
    end 
    [B,D] = eig(S{1},S{2});    
    [D, ind]=sort(diag(D));B=B(:,ind);
    result = B'*W;
  end
  